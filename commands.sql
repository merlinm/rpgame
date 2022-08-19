/* Application facing API for managing commands before conversion to fleet  */

/*
 * Creates a command. Runs as superuser so that players can execute the function
 * without necessarily seeing the contents of the command table.
 SELECT AddCommand('X', 'z', 5);
 *
 * Adds command to command table
 * Validate the inputs
 *   Not enough ships
 *   Source planet not owned by command creator
 *   Ships on planet but allocated to another command
 *   Source planet does not exist
 *   Destination planet does not exist
 *   Player does not exist
 *   Game does not exist
 *   Player and and game exist, but player is attached to game
 *   Planet is not attached to game
 *
 * If GameId is not supplied, the system will look up games attached to the
 * player, and, if there is only one active game, resove it.
 *
 *  #1 players not to play more than one game at a time
 *  #2 only one game at a time period
 *
 * Commands are checked for validity immediately, any command that can be
 * processed due to being in violation of game rules are returned in error.
 *
 *  Commands must:
 *    not send more ships than are available in the planet, with consideration
 *     for allocated ships.
 *    send from a planet owned by the issuing player
 *    must have a valid distination
 *    source and destination should not be the same
 *    must send at least one ship
 *
 */

CREATE OR REPLACE FUNCTION AddCommand(
  _SourceDisplayCharacter TEXT,
  _DestinationDisplayCharacter TEXT,
  _NumberOfShips INT,
  _GameId INT DEFAULT NULL,
  _Player TEXT DEFAULT current_user) RETURNS VOID AS
$$
DECLARE
  _PlayerGameCount INT;
  p Planet;
  d Planet;

  _AllocatedShips INT;
BEGIN
  /* Resolve gameid if not explicitly passed. */
  IF _GameId IS NULL
  THEN
    PERFORM ResolveGameId(_Player);
  END IF;

  /* verify and store source planet */
  SELECT * INTO p
  FROM Planet
  WHERE
    GameId = _GameId
    AND Owner = _Player
    AND DisplayCharacter = _SourceDisplayCharacter;

  IF NOT FOUND
  THEN
    RAISE EXCEPTION 'Player % does not own planet % for game %',
      _Player, _SourceDisplayCharacter, _GameId;
  END IF;

  /* verify destination planet */
  SELECT * INTO d
  FROM Planet
  WHERE
    GameId = _GameId
    AND DisplayCharacter = _DestinationDisplayCharacter;

  IF NOT FOUND
  THEN
    RAISE EXCEPTION 'Planet % does not exist for game %',
      _DestinationDisplayCharacter, _GameId;
  END IF;

  /* source and destination planet must not be the same */
  IF p.DisplayCharacter = d.DisplayCharacter
  THEN
    RAISE EXCEPTION
      'Source and destination planet % must not be the same',
      _DestinationDisplayCharacter;
  END IF;

  /* ship count validation: ships on planet (discounted for allocated ships),
   * must be greater than or equal to command number of ships
   */
  SELECT INTO _AllocatedShips
    SUM(NumberOfShips)
  FROM Command
  WHERE
    SourcePlanetId = p.Planet;

  IF p.Ships < _AllocatedShips + _NumberOfShips
  THEN
    RAISE EXCEPTION
      'Planet % with ship count % (% allocated) '
      'cannot support command with % ships',
      _SourceDisplayCharacter,
      p.Ships,
      _AllocatedShips,
      _NumberOfShips;
  END IF;

  /* ship count submission >= 1 */
  IF _NumberOfShips < 1
  THEN
    RAISE EXCEPTION
      'Submitted ship count % must be at least one'
      _NumberOfShips;
  END IF;

  INSERT INTO Command(
    SourcePlanetId,
    DestinationPlanetId,
    PlayerName,
    NumberOfShips)
  VALUES (
    (
      SELECT PlanetId
      FROM Planet
      WHERE
        DisplayCharacter = _SourceDisplayCharacter
        AND GameId = _GameId
    ),
    (
      SELECT PlanetId
      FROM Planet
      WHERE
        DisplayCharacter = _DestinationDisplayCharacter
        AND GameId = _GameId
    ),
    _Player,
    _NumberOfShips
  );
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;


/* Show commands for a player that have entered but not processed.
 *
 * XXX: delete command function needed?
 *
 * Today we do this!
 */
CREATE OR REPLACE FUNCTION ShowCommands(
  _Player TEXT DEFAULT current_user,
  _GameId INT DEFAULT NULL) RETURNS SETOF TEXT AS
$$
BEGIN
  /* Resolve gameid if not explicitly passed. */
  IF _GameId IS NULL
  THEN
    PERFORM ResolveGameId(_Player);
  END IF;

  SELECT
    format('%s. %s ships from %s to %s',
      row_number() OVER (ORDER BY CommandId),
      c.NumberOfShips,
      ps.DisplayCharacter,
      pd.DisplayCharacter)
  FROM Command c
  JOIN Planet ps ON SourcePlanetId = ps.PlanetId
  JOIN Planet pd ON DestinationPlanetId = pd.PlanetId
  WHERE
    PlayerName = _Player;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;


/*
 * HARD DELETE: delete the record
 *   not able to provide any audit
 *
 * SOFT DELETE: mark a flag, check flag where the record might be used
 *   *) provides auditing or historical record
 *   *) storage needs
 *   *) requires developer to check everywhere (can mitigated with view)
 *
 * HARD DELETE + AUDIT: move record to audit table
 *   *) provides auditing or historical record
 *   *) storage needs
 *   *) more complex
 *   *) better choice when there are formal auditing needs
 */


/*
 * Create fleets from commands.
 * update command table, insert into fleets
 */
CREATE OR REPLACE FUNCTION ProcessCommands(_GameId INT) RETURNS VOID AS
$$
BEGIN

  WITH processed AS
  (
    UPDATE Command c SET
      Processed = now()
    FROM
    (
      SELECT *
      FROM vw_PendingCommand vc
      WHERE
        vc.SourcePlanetId IN (
          SELECT PlanetId
          FROM Planet
          WHERE GameId = _GameId
        )
    ) q
    WHERE q.PlanetId = c.PlanetId
    RETURNING *
  )
  INSERT INTO Fleet(
    PlayerName,
    DestinationPlanetId,
    ShipCount,
    TurnsLeft)
  SELECT
    PlayerName,
    DestinationPlanetId,
    NumberOfShips,
    Distance(
      source.XPosition,
      source.YPosition,
      destination.XPosition,
      destination.YPosition)
  FROM processed c
  JOIN Planet source ON c.SourcePlanetId = source.PlanetId
  JOIN Planet destination ON c.DestinationPlanetId = destination.PlanetId;

END;
$$ LANGUAGE PLPGSQL;

/* Decrement all fleets in transit by one turn.
 */
CREATE OR REPLACE FUNCTION MoveFleets(_GameId INT) RETUNS VOID AS
$$
BEGIN
  UPDATE Fleet f SET TurnsLeft = TurnsLeft - 1
  WHERE (
    f.DesinationPlanetId IN (
      SELECT PlanetId
      FROM Planet
      WHERE GameId = _GameId
    );
END;
$$ LANGUAGE PLPGSQL;

/*
 *
 * Each ship will role a six sided die and score a hit with six.
 * Shots happens simultaneously and a hit will remove a ship from the other
 * side. Battle continues until one or both sides have no ships remaning.
 * Defense value are 'bonus ships' that cannot be destroyed but contribute
 * to defending fleet.
 */
CREATE OR REPLACE FUNCTION Battle(
  f Fleet,
  AttackingShipsRemaining OUT INT,
  DefendingShipsRemaining OUT INT) RETURNS RECORD AS
$$
DECLARE
  p Planet;

  _AttackerHits INT;
  _DefenderHits INT;
BEGIN
  SELECT INTO p * FROM Planet WHERE PlanetId = f.DesinationPlanetId;

  DefendingShipsRemaining := p.Ships;
  AttackingShipsRemaining := f.ShipCount;

  LOOP
    SELECT INTO _AttackerHits COUNT(*)
    FROM DiceRoller(1, 6, AttackingShipsRemaining) d
    WHERE d = 6;

    SELECT INTO _DefenderHits COUNT(*)
    FROM DiceRoller(1, 6, DefendingShipsRemaining + p.Defense) d
    WHERE d = 6;

    /* roll dice and adjust the ship counts */
    DefendingShipsRemaining :=
      greatest(DefendingShipsRemaining - _AttackerHits, 0);

    AttackingShipsRemaining :=
      greatest(AttackingShipsRemaining - _DefenderHits, 0);

    IF AttackingShipsRemaining = 0 OR DefendingShipsRemaining = 0
    THEN
      EXIT;
    END IF;
  END LOOP;
END;
$$ LANGUAGE PLPGSQL STABLE;


/*
 * For fleets with turncount = 0,
 * the fleet will engage in battle if the destination planet is owned by another
 * player, or accumulate ship count if the planet is owned by the seding player.
 *
 * Regardless of the above, the fleet will no longer exist upon arrival.
 */
CREATE OR REPLACE FUNCTION ProcessFleetArrivals(_GameId INT) RETUNS VOID AS
$$
DECLARE
  f Fleet;
  _NeedBattle BOOL;
  _DefendingShipsRemaining INT;
  _ShipsRemaining INT;
BEGIN
  FOR f IN
    SELECT * FROM Fleet
    WHERE (
      f.DesinationPlanetId IN (
        SELECT PlanetId
        FROM Planet
        WHERE GameId = _GameId
      ) AND TurnsLeft = 0
  LOOP
    /* check if planet is owned by fleet owner and give battle if it isn't */
    SELECT INTO
      _NeedBattle
      p.Owner != f.PlayerName
    FROM Planet p
    WHERE
      f.DestinationPlanetId = p.PlanetId;

    _FleetDestroyed := false;

    IF _NeedBattle
    THEN
      /* battle function reduces ship count for fleet and planet until
       * one or the other has no ships remaining
       */
      SELECT INTO _ShipsRemaining, _DefendingShipsRemaining * FROM Battle(f);
    ELSE
      _ShipsRemaining := f.NumberOfShips;
    END IF;

    DELETE FROM Fleet f2
    WHERE f2.FleetId = f.FleetId;

    /* if battle was given and fleet does not survive, terminate fleet */
    IF _ShipsRemaining = 0
    THEN
      CONTINUE;
    END IF;

    /* if battle was given and fleet does survive, change planet owner to fleet
     * owner.
     */
    UPDATE Planet SET
      Owner = CASE
        WHEN _NeedBattle AND _ShipsRemaining > 0 Owner THEN f.PlayerName
        ELSE Owner
      END,
      Ships = CASE
        WHEN _NeedBattle AND _ShipsRemaining > 0 THEN _ShipsRemaining
        WHEN _NeedBattle AND _ShipsRemaining = 0 THEN _DefendingShipsRemaining
        ELSE Ships + _ShipsRemaining
      END
    WHERE PlanetId = f.DestinationPlanetId;
  END LOOP;

  /* XXX: consider battle reports yep
   *
   * Upon turn conclusion, users will receive a report of battles. But how??
   *
   */

END;
$$ LANGUAGE PLPGSQL;


/* format fleet reports.
 *
 * examples: fleet with X ships sent from planet Y has arrived without battle
 *             at planet z.
 *           fleet with X ships sent from planet Y has arrived with battle
 *             at planet z and is victorious with W ships surviving
 *           fleet with X ships sent from planet Y has arrived with battle
 *             at planet z and was defeated
 *
 */
CREATE OR REPLACE FUNCTION BattleReport(
  _,
  _) RETURNS TEXT AS
$$
  /* choice #1 :-) I agree*/
  SELECT
    CASE
      WHEN x THEN format(
        'fleet with %s ships sent from planet %s has arrived without battle'
        ' at planet %s.'
      WHEN y THEN format(..
      WHEN z THEN format(
    END;

$$ LANGUAGE SQL;



/*
 * Convert ships to fleets and clear commands table
 *
 * Let's discuss behavior.
 *   Option 1. CommandsDone() returns immediately, always.
 *     Two ways to be notified that game state has changed
 *       1a. Poll (just ask every so often)
 *
 *       1b. Push Notification (Pam, Roland, Shruti, Merlin)
 *     1a and 1b are two variants of asynchronous communication
 *
 *   In a crash scenario,
 *     Send CommandsDone in special mode, so that it only hangs if your flag is
 *     still yet, other wise, it will immediately print battle repots (if any)
 *     and exit.
 *
 *   Option 2. CommandsDone() hangs until every player has issues CommandsDone()
 *     and prints out battle reports
 *
 *   Option 2a. As #2, but no battle reports. (Karls, Kyle, Valencia)
 *     2a and 2b are synchronous communcation.  Often a timeout is needed.
 *     Synchronous communcation can be a poor choice when the thing being
 *     processed has an arbitrary runtime.
 *     Synchronous is good choice when runtime is expected to be short and
 *     bounded.
 *
 *     All else being equal, synchronous designs are simpler
 *     We do not want our synchronous command to hold a transaction open if
 *     possible.
 *
 *   Set a flag on PlayerGame table, commit the transaction, then wait around
 *     for all other flags to be set, printing battle reports when ther all set
 */
CREATE OR REPLACE FUNCTION CommandsDone(
  _Player TEXT DEFAULT current_user,
  _GameId INT DEFAULT NULL) RETURNS SETOF TEXT AS
$$
BEGIN
  IF NOT AllPlayersDone() /*XXX: TODO */
  THEN
    /* nothing to do! */
    RETURN;
  END IF;

  /* Game turn processing */
  PERFORM ProcessCommands(_GameId);

  PERFORM MoveFleets(_GameId);

  PERFORM ProcessFleetArrivals(_GameId);

  PERFORM SendUserReports(_GameId);
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;



