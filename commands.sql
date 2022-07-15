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
  // get the data
  select * from command where SourcePlanetId IN (
      SELECT PlanetId
      FROM Planet
      WHERE GameId = _GameId
    )

    // for c in returned commands loop
    update command set processed where commandid = c.commandid;
    insert into fleet ...
  end loop


  /* OLD SCHOOL: get results, store in temp table. either,
     loop with cursor,
     OR
     UPDATE FROM temp / INSERT FROM temp

    */

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
      x1,y1,x2,y2
      )
  FROM processed c
  JOIN Planet source ON c.SourcePlanetId = source.PlanetId
  JOIN Planet destination ON c.DestinationPlanetId = destination.PlanetId



END;
$$ LANGUAGE PLPGSQL;





/*
 * Convert ships to fleets and clear commands table
 */
CREATE OR REPLACE FUNCTION CommandsDone(
  _Player TEXT DEFAULT current_user,
  _GameId INT DEFAULT NULL) RETURNS SETOF TEXT AS
$$
  IF NOT AllPlayersDone() /*XXX: TODO */
  THEN
    /* nothing to do! */
    RETURN;
  END IF;

  /* Game turn processing */
  PERFORM ProcessCommands();

  PERFORM MoveFleets();

  PERFORM EnageBattles();

  PERFORM SendUserReports();

$$ LANGUAGE PLPGSQL SECURITY DEFINER;



