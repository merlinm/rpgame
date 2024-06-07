



CREATE OR REPLACE FUNCTION AdvanceTurn(_GameId INT) RETURNS VOID AS
$$
BEGIN
  /* Game turn processing */
  RAISE NOTICE 'Processing commands for GameId %', _GameId;
  PERFORM ProcessCommands(_GameId);

  RAISE NOTICE 'Moving fleets for GameId %', _GameId;
  PERFORM MoveFleets(_GameId);

  RAISE NOTICE 'Processing fleet arrivals for GameId %', _GameId;
  PERFORM ProcessFleetArrivals(_GameId);

  RAISE NOTICE 'Turn advancement for GameId % done, advancing turn', _GameId;
  UPDATE Game SET 
    Turn = Turn + 1, 
    LastTurnChange = clock_timestamp()
  WHERE GameId = _GameId;

  UPDATE PlayerGame SET CommandsDone = NULL
  WHERE GameId = _GameId;

  UPDATE Planet SET
    Ships = Ships + Production
  WHERE GameId = _GameId;

END;
$$ LANGUAGE PLPGSQL;


/* Advance the turn if all players have completed their turn or
 * it has been X time since first player submitted a command.
 *
 * Answers the question, "are we ready to advance turn?"
 */
CREATE OR REPLACE FUNCTION AllPlayersDone(
  _GameId INT,
  ReadyToAdvance OUT BOOL) RETURNS BOOL AS
$$
DECLARE
  g Game;
BEGIN
  SELECT Into g * FROM Game WHERE GameId = _GameId;

  SELECT INTO ReadyToAdvance
    NOT EXISTS (
      SELECT 1
      FROM PlayerGame
      WHERE
        GameId = _GameId
        AND CommandsDone IS NULL
    ) OR clock_timestamp() - (
      SELECT
        MIN(CommandsDone)
      FROM PlayerGame
      WHERE GameId = _GameId
    ) > g.TurnTimeout
    OR (
      NOT g.PlayerInputRequired
      AND clock_timestamp() - g.LastTurnChange
      > g.TurnTimeout
   );
END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION AdvanceGameState(
  DidStuff OUT BOOL) RETURNS BOOL AS
$$
BEGIN
  /* need to check for various things, but for now, if all commands are done
   * for a particular game. if (for any game) all commands are done, we shall
   * advance the turn for that game.
   */
  PERFORM AdvanceTurn(GameId)
  FROM Game
  WHERE
    Ended IS NULL
    AND AllPlayersDone(GameId);

  DidStuff := FOUND;
END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE PROCEDURE Main() AS
$$
DECLARE
  r RECORD;
  _DidStuff BOOL;
BEGIN
  /* are there things to do? */
  LOOP
    RAISE NOTICE 'checking for things to do';

    _DidStuff := false;

    _DidStuff := AdvanceGameState();

    IF _DidStuff
    THEN
      COMMIT;
    ELSE
      RAISE NOTICE 'nothing to do...sleeping.';
      PERFORM pg_sleep(5.0);
    END IF;
  END LOOP;

  /* if so do them. otherwise sleep a bit */
END;
$$ LANGUAGE PLPGSQL;