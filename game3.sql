/*
 * EDITING CODE:
 *
 * Editing:
 *   IDE Camp
 *     Visual Studio, Netbeans, Eclipse
 *     Very Heavy (slow), Feature Packed
 *     Directed towards narrow technical stack
 *     Vendor Directed
 *     $$$
 *   Fancy Text Editor Camp
 *     FOSS (free/open source)
 *     Knowledge tends to be technically diverse
 *     TextMate, Notepad++, Submlime Text, Vim, Emacs
 *
 * Databases 
 *    Console (psql, sqsh, isql)
 *    Vendor Provide Tool (SQL Server Enterprise Studio, PGAdmin)
 *    Cross Database (Aqua Data Studio,  DBVisualizer), $$$, slower
 *
 * Today we are going to talk about SDLC, code management, all kinds of stuff
 *   with some cool military analogies
 *
 * It's nollig time
 *
 * one more song, need to get into coding mode :-).
 *
 * Hopefully we were all able to get github installed, desktop with project set
 * up
 *
 * TODO:
 *   enhance playfield to show planet listing
 *   commands?
 *
 *                                FUN SPECTRUM
 *   <---------------------------------------------------------------------->
 *   Less fun                                                         More fun
 *      security                                                    graphics
 *   PI PLANNING                                                      sql class
 *   launch projects
 *
 */


/*
 *
 * WELCOME NEW FACES !!  ---
 * RITUAL: 5 MINUTE MUSICAL warm up  80's today  Kyle (younger than I) : Stevie B -- spring love
 *         lecture(not completely boring)
 *         coding
 *         git logins coming soon (-:   <-- 
 *
 * next week:
 *
 * Game intialization  (Take a list of payers)  -- working
 *   Verify at least 2 players  *
 *   Generate playfield *
 *   Insert game record *
 *
 * Turn/phase processing  on deck
 * Processing commands into fleets (function / procedure) on deck
 *   Distance function *
 * Process fleets in transit on deck <-- today
 * Battles, ship to planet combat
 *  Dice roller *
 *
 * Security model *
 *
 * Playfield display function *
 *
 *  INSERT INTO Command...
 *  Fog of war: no visibility to commands
 *    Option #1: honor system, assume nobody inspects command or fleet table
 *    Option #2: database security
 *
 */


/* 
 * Represents an instance of a game, 
 * each record represents a single game 
 */
CREATE TABLE Game 
(
  GameId SERIAL PRIMARY KEY,

  Started TIMESTAMPTZ NOT NULL,
  Ended TIMESTAMPTZ,

  Winner TEXT,
 
  PlayFieldWidth INT NOT NULL,
  PlayFieldHeight INT NOT NULL,
  
  Turn INT DEFAULT 1
);



CREATE TABLE PlayerGame
(
  PlayerName TEXT REFERENCES Player
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  GameId INT REFERENCES Game ON DELETE CASCADE,
  
  HomePlanetId INT /* REFERENCES Planet(PlanetId) */,
  Ally TEXT,
  
  UNIQUE(PlayerName, GameId)
);

CREATE INDEX ON PlayerGame(GameId);




-- optimized, PlayerName, (PlayerName, GameId) 
-- not optimized: GameId


-- kyle
-- Planet one:many  game:planet
CREATE TABLE Planet 
(
  PlanetId SERIAL PRIMARY KEY,
  
  GameId INT,
  Owner TEXT, /* can be null when unowned */
  
  Production INT CHECK 
    (Production BETWEEN 0 AND 10),

  /* NULL denotes neutral ?? 
    1. Upon insertion, owner MUST be in player
    2. By default, if a player is deleted so that rule #1 is violated,
       abort the query.
    3. By default, if a player name is adjusted so that rule #1 is violated,
       abort the query.
   */

  Defense INT,

  Ships INT,
  
  XPosition INT,
  YPosition INT,


  DisplayCharacter TEXT/* NOT NULL CHECK (Length(DisplayCharacter) = 1) */,

  
  FOREIGN KEY(GameId, Owner) REFERENCES PlayerGame(GameId, PlayerName)
   ON UPDATE CASCADE ON DELETE CASCADE,


  FOREIGN KEY(GameId) REFERENCES Game ON UPDATE CASCADE ON DELETE CASCADE,

  UNIQUE(GameId, XPosition, YPosition),

  UNIQUE(GameId, DisplayCharacter)
);


ALTER TABLE PlayerGame ADD FOREIGN KEY(HomePlanetId) REFERENCES 
  Planet(PlanetId);

CREATE OR REPLACE VIEW vw_Game AS
  SELECT 
    g.*,
    COUNT(*) AS PlayerCount
  FROM Game g
  JOIN PlayerGame USING(GameId)
  GROUP BY GameID;


CREATE TABLE Command
(
  CommandId INT,

  SourcePlanetId INT REFERENCES Planet,
  DestinationPlanetId INT REFERENCES Planet,
  PlayerName TEXT,
  
  NumberOfShips INT,

  Processed TIMESTAMPTZ,

  PRIMARY KEY(PlayerName, SourcePlanetId, DestinationPlanetId)
);


CREATE OR REPLACE VIEW vw_PendingCommands AS
  SELECT
    *,
    GameId
  FROM Command
  --JOIN Game ON Command
  WHERE Processed IS NULL;


/*
 * Each record represents a number of ships in transit
 */
CREATE TABLE Fleet 
(
  FleetId INT,
  
  PlayerName TEXT REFERENCES Player,
  DestinationPlanetId INT, 
  Created INT, /* fleet was create on this turn */
  
  ShipCount INT,
  TurnsLeft INT,
  
  PRIMARY KEY(PlayerName, DestinationPlanetId, Created)
);


-- player owned alliance
1. Create the alliance
2. Attach players the alliance from the alliance
3. more capability

CREATE TABLE Alliance
(
  GameId INT REFERENCE Game,
  AllianceOwner TEXT REFRENCES Player,
  PRIMARY KEY (GameId, AllianceOwner)
);

CREATE TABLE AllianceMember
( 
  GameId INT,
  AllianceOwner TEXT 
  AllianceMember TEXT,

  PRIMARY KEY(GameId, AllianceOwner, AllianceMamber),
  FOREIGN KEY(GameId, AllianceOwner) 
    REFERENCES Alliance
);


-- discrete relationship
CREATE TABLE Alliance
(
  PlayerName1 TEXT,
  PlayerName2 TEXT
);

-- simpler


/*
 *
  SELECT Distance(
    0, 3,
    4, 0)
  */

/*
 * Mainly used to determine number of turns 
 * ships will spend in transit.
 */
CREATE OR REPLACE FUNCTION Distance(
  _XPosition1 INT,
  _YPosition1 INT,
  _XPosition2 INT,
  _YPosition2 INT,
  Turns OUT INT) RETURNS INT AS
$$
  SELECT 
    ceil(sqrt(
      abs(_XPosition2 - _XPosition1) ^ 2 + 
      abs(_YPosition2 - _YPosition1) ^ 2))::INT;
$$ LANGUAGE SQL;


  
  


/*
 * next week:
 *
 * Game intialization  (Take a list of payers)
 *   Verify at least 2 players
 *   Generate playfield
 *   Insert game record
 * Turn/phase processing
 * Processing commands into fleets (function / procedure)
 *   Distance function
 * Process fleets in tranit
 * Battles, ship to planet combat
 *  Dice roller
 *
 * Playfield display function
 */



CREATE OR REPLACE VIEW vw_Game AS
  SELECT 
    g.*,
    COUNT(*) AS PlayerCount
  FROM Game g
  JOIN PlayerGame USING(GameId)
  GROUP BY GameID;


CREATE TABLE Command
(
  CommandId INT,

  SourcePlanetId INT REFERENCES Planet
  DestinationPlanetId INT REFERENCES Planet,
  PlayerName TEXT,
  
  NumberOfShips INT,
  PRIMARY KEY(PlayerName, SourcePlanetId, DestinationPlanetId)
);


/*
 * A fleet is stationed a planet if TurnsLeft = 0
 */
CREATE TABLE Fleet 
(
  FleetId INT,
  
  PlayerName TEXT REFERENCES Player,
  DestinationPlanetId INT, 
  Created INT, /* fleet was create on this turn */
  
  ShipCount INT,
  TurnsLeft INT,
  
  PRIMARY KEY(PlayerId, DestinationPlanetId, Created)
);


-- player owned alliance
1. Create the alliance
2. Attach players the alliance from the alliance
3. more capability

CREATE TABLE Alliance
(
  GameId INT REFERENCE Game,
  AllianceOwner TEXT REFRENCES Player,
  PRIMARY KEY (GameId, AllianceOwner)
);

CREATE TABLE AllianceMember
( 
  GameId INT,
  AllianceOwner TEXT 
  AllianceMember TEXT,

  PRIMARY KEY(GameId, AllianceOwner, AllianceMamber),
  FOREIGN KEY(GameId, AllianceOwner) 
    REFERENCES Alliance
);


-- discrete relationship
CREATE TABLE Alliance
(
  PlayerName1 TEXT,
  PlayerName2 TEXT

);

-- simpler


/*
 *
  SELECT Distance(
    0, 3,
    4, 0)
  */

CREATE OR REPLACE FUNCTION Distance(
  _XPosition1 INT,
  _YPosition1 INT,
  _XPosition2 INT,
  _YPosition2 INT,
  Turns OUT INT) RETURNS INT AS
$$
  SELECT 
    ceil(sqrt(
      abs(_XPosition2 - _XPosition1) ^ 2 + 
      abs(_YPosition2 - _YPosition1) ^ 2))::INT;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION DiceRoller(
  _NumberOfSides INT,
  _NumberOfDices INT) RETURNS SETOF INT AS
$$
  SELECT ((random() * _NumberOfSides) + 0.5)::int 
  FROM generate_series(1, _NumberOfDices);  
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION DiceRoller(
  _DiceLowValue INT,
  _DiceHighValue INT,
  _NumberOfDices INT) RETURNS SETOF INT AS
$$
  SELECT
    ((random() * ((_DiceHighValue - _DiceLowValue) + 1) + 0.5))::INT
      + _DiceLowValue - 1
  FROM generate_series(1, _NumberOfDices);  
$$ LANGUAGE SQL;



-- Interface (browser) Accept Input, Validate, Display, Interact with human (do much here)
-- Application (backend language -- database), Secure, Act, Interact w/ data model
-- Data Model (what is (or can be) and what isn't (or can't)).

/*
  \IIIII/ Interface                 time and money
----API------
   \BBB/  Business Logic
    \B/   Database Procedures
     D    Data Model
*/

CALL InitializeGame(
  array[
    'Merlin',
    'Pam',
    'James',
    'Karls',
    'Kyle']);


function add_two(a, b)
  return a + b;    
  
  
CALL InitializeGame(array['Karls', 'Merlin', 'Pam']);


/* 
 * initiailzes playfield, attaches players to map.
 */
CREATE OR REPLACE PROCEDURE InitializeGame(
  _Players TEXT[],
  _NumberOfPlanets INT DEFAULT 30,
  _PlayFieldWidth INT DEFAULT 20,
  _PlayFieldHeight INT DEFAULT 20) AS
$$
DECLARE
  _GameId BIGINT;
  _PlanetId INT;
  i INT;
  
  _MapPlanetOccupancy NUMERIC DEFAULT .2;
  
  pg PlayerGame;
BEGIN
  /* Verify at least 2 players 
   *
   * No idea - can we add CHECK(COUNT(select * FROM Player) 
   *  > 2 to the player or playergame table
   */
  
  IF array_upper(_Players, 1) < 2
  THEN
    RAISE EXCEPTION 'Not enough players';
  END IF;
  
  IF _NumberOfPlanets < 5
  THEN
    RAISE EXCEPTION 'Not enough planets';  
  END IF;  
  
  /* the number of players must be smaller than the number of planets */
  IF array_upper(_Players, 1) > _NumberOfPlanets
  THEN
    RAISE EXCEPTION '%', format(
      'Planet count %s can not accommodate %s players',
      _NumberOfPlanets,
      array_upper(_Players, 1));
  END IF;
  
  
  /* Make sure playfield is large enough to accommodate the planets */
  IF _NumberOfPlanets > _PlayFieldWidth * _PlayFieldHeight * _MapPlanetOccupancy
  THEN
    RAISE EXCEPTION '%',
      format(
        'Number of planets %s exceeds threshold for playfield width %s height %s',
        _NumberOfPlanets, 
        _MapPlanetOccupancy,
        _PlayFieldWidth,
        _PlayFieldHeight);
  END IF;
  
  
  /* accept players that are new otherwise ignore */
  INSERT INTO Player (PlayerName)
  SELECT Player FROM UNNEST(_Players) AS Player
  ON CONFLICT DO NOTHING;

  INSERT INTO Game (GameId, Started, PlayFieldWidth, PlayFieldHeight)
  VALUES (DEFAULT, CURRENT_TIMESTAMP, _PlayFieldWidth, _PlayFieldHeight)
  RETURNING GameId INTO _GameId; 
  
  /* Generate playfield 
   *
   * Do not generate 2+ planets on same square
   *
   * XXX: Does not account for more planets than available positions.
   *
   */
  FOR i in 1.._NumberOfPlanets
  LOOP /* one iteration for each planet we want to insert */
    LOOP /* loop the planet as represented  by 'i' is succesfully inserted */
      BEGIN
        INSERT INTO Planet(
          PlanetId,
          GameId,
          Owner,
          Production,
          Defense,
          Ships,
          XPosition,
          YPosition,
          DisplayCharacter)
        VALUES (
          DEFAULT,
          _GameId,
          NULL,
          DiceRoller(0, 11, 1), 
          DiceRoller(5, 20, 1),
          0,
          DiceRoller(_PlayFieldWidth, 1),
          DiceRoller(_PlayFieldHeight, 1),
          chr(i + 47));
      EXCEPTION WHEN others THEN
        /* XXX: Does not account for specific failure condition */
        RAISE WARNING 'Got % while inserting planet during iteraton %', SQLERRM, i;
        
        CONTINUE;
      END;
      
      EXIT;
    END LOOP;
  END LOOP;
  
  /* attach players to the game
   *
   * XXX: record home planet?
   */
  INSERT INTO PlayerGame(PlayerName, GameId)
  SELECT 
    p,
    _GameId
  FROM UNNEST(_Players) p;
  
  /* attach owners
   * HOW?? --- assign random planet id to player
   * get 

   */
  
  /* loop players attached to the game */
  FOR pg IN SELECT * FROM PlayerGame WHERE GameId = _GameId
  LOOP
    /* Randomly select a planet */
    SELECT PlanetId INTO _PlanetId
    FROM Planet
    WHERE 
      GameId = _GameId
      AND Owner IS NULL
    ORDER BY random() LIMIT 1;  

    /* Assign the owner to that planet */
    UPDATE Planet SET
      Owner = pg.PlayerName,
      Production = 10,
      Ships = 10
    WHERE 
      PlanetId = _PlanetId;
      
    /* Mark the home planet on the player game record */
    UPDATE PlayerGame SET HomePlanetId = _PlanetId
    WHERE 
      GameId = _GameId
      AND PlayerName = pg.PlayerName;
  END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION ResolveGameId(
  _Player TEXT DEFAULT current_user,
  GameId OUT INT) RETURNS INT AS
$$
DECLARE
  _PlayerGameCount INT;
  _GameId INT;
BEGIN
  /* Is the user playing 2 or more active games? If so, abort */
  SELECT
    COUNT(*), min(g.GameId)
    INTO _PlayerGameCount, _GameId
  FROM PlayerGame pg
  JOIN Game g USING(GameId)
  WHERE
    PlayerName = _Player
    AND Ended IS NULL;

  IF _PlayerGameCount = 0
  THEN
    RAISE EXCEPTION 'Player % is not involved in any games', _Player;
  END IF;

  IF _PlayerGameCount >= 2
  THEN
    RAISE EXCEPTION
      'Player % is attached to multiple games, game id must be supplied',
      _Player;
  END IF;

  GameId := _GameId;
END;
$$ LANGUAGE PLPGSQL;




/*
 * how do we align display horizontally? hmm.
 *
 * let's do that today!
 */
CREATE OR REPLACE FUNCTION ShowPlayfield(
  _Player TEXT DEFAULT current_user,
  _GameId INT DEFAULT NULL) RETURNS SETOF TEXT AS
$$
DECLARE
  g Game;
  _DisplayCharacter TEXT;
  _row INT;
  _column INT;

  _DisplayRow TEXT;

  _DisplayHeight INT;

  _PlanetDisplay TEXT[];
  _MapDisplay TEXT[];

  _DisplayRows TEXT[];
BEGIN
  /* Resolve gameid if not explicitly passed. */
  IF _GameId IS NULL
  THEN
    _GameId := ResolveGameId(_Player);
  END IF;

  SELECT * INTO g
  FROM Game WHERE GameId = _GameId;

  -- max, greatest(), IF/ELSE plpgsql, CASE
  SELECT INTO _DisplayHeight
    greatest(
      (
        /* reserve an extra row for header */
        SELECT COUNT(*) + 1
        FROM Planet
        WHERE GameId = _GameId
      ),
      (
        g.PlayFieldHeight
      )
    );

  FOR _row in 1..g.PlayFieldHeight
  LOOP
    _DisplayRow := '';

    FOR _column in 1..g.PlayFieldWidth
    LOOP
      SELECT
        DisplayCharacter INTO _DisplayCharacter
      FROM Planet
      WHERE
        GameId = _GameId
        AND XPosition = _column
        AND YPosition = _row;

      IF NOT FOUND
      THEN
        _DisplayCharacter := '.';
      END IF;

      _DisplayRow := _DisplayRow || _DisplayCharacter;
    END LOOP;

    _MapDisplay := _MapDisplay || _DisplayRow;
  END LOOP;

  /* XXX: lazy; printing planet list after map
   * blank line first
   */

  SELECT INTO _PlanetDisplay
    array_agg(row)
  FROM
  (
    /* header row */
    SELECT 'Planet    Owner            # Ships    Production    Defense'  AS row
    UNION ALL SELECT
      format(
        '%s    %s    %s    %s    %s',
        rpad(DisplayCharacter, 6, ' '),
        rpad(COALESCE(Owner, ''), 13, ' '),
        lpad(Ships::TEXT, 7, ' '),
        lpad(Production::TEXT, 10, ' '),
        lpad(Defense::TEXT, 7, ' '))
    FROM Planet
    WHERE GameId = _GameId
  ) q;

  RETURN QUERY SELECT
    format('%s   %s',
      COALESCE(m.v, lpad('', g.PlayFieldWidth, ' ')),
      p.v)
  FROM generate_series(1, _DisplayHeight) DisplayRow
  LEFT JOIN
  (
    SELECT * FROM unnest(_MapDisplay) WITH ORDINALITY v
  ) m ON DisplayRow = m.Ordinality
  LEFT JOIN
  (
    SELECT * FROM unnest(_PlanetDisplay) WITH ORDINALITY v
  ) p ON DisplayRow = p.Ordinality;

END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;


/*
 *  Not every feet has a battle report, but every battle report has a fleet.
 *  Relationship between fleet and bettle report is 1:1
 */
CREATE TABLE BattleReport
(
  GameId INT,
  BettleReportId SERIAL,

  Turn INT,

  SendingPlayerName TEXT,
  ReceivingPlayerName TEXT,

  /* the turn the fleet arrive */
  FleetArrivalTurn INT,

  WasBattle BOOL,

  SenderSurvivingShipCount INT,
  ReceiverSurvivingShipCount INT,

  DidPlanetChangedHands BOOL,

  SourcePlanetId INT,
  DestinationPlanetId INT,

  /*
   * option 1: IsSender is captured, with two records, one for attacker ,
   *           one for defender
   * option 2: one record PER BATTLE, with is Attacker decision made by looking
   *           at who is requesting reports.
   *
   *   less duplication of data
   *   easier generation
   */

);

CREATE OR REPLACE FUNCTION FormatBattleReport(
  b BattleReport,
  _IsSender BOOL) RETURNS TEXT
$$
BEGIN

  CASE
    WHEN NOT b.WasBattle AND _IsSender THEN
      RETURN format(
        'fleet with %s ships sent from planet %s has arrived without battle'
        ' at planet %s.',
        b.SentShipCount,
        (SELECT DisplayCharacter FROM Planet WHERE PlanetId = SourcePlanetId),
        (
            SELECT DisplayCharacter
            FROM Planet
            WHERE PlanetId = DestinationPlanetId
        ));

    WHEN b.WasBattle AND _IsSender THEN
      RETURN format(
        'fleet with %s ships sent from planet %s has arrived with battle'
        ' at planet %s and is victorious with %s ships surviving',
        b.SentShipCount,
        (SELECT DisplayCharacter FROM Planet WHERE PlanetId = SourcePlanetId),
        (
            SELECT DisplayCharacter
            FROM Planet
            WHERE PlanetId = DestinationPlanetId
        ));

  END CASE;


  IF NOT b.WasBattle AND _IsSender
  THEN

  ELSEIF b.WasBattle AND _IsSender
  THEN
    RETURN format(
      'fleet with %s ships sent from planet %s has arrived without battle'
      ' at planet %s.',
      b.SentShipCount,
      (SELECT DisplayCharacter FROM Planet WHERE PlanetId = SourcePlanetId),
      (
          SELECT DisplayCharacter
          FROM Planet
          WHERE PlanetId = DestinationPlanetId
      ));
  END IF;


END;
$$ LANGUAGE PLPGSQL;

PrintBattleReports(_GameId, _Player, _Turn DEFAULT...) RETURNS SETOF TEXT
  SELECT FROM BattleReport WHERE GAME = x and Turn =  Y AND (Sending OR RecivingPlayer) _Player

 * examples: fleet with X ships sent from planet Y has arrived without battle
 *             at planet z.
 *           fleet with X ships sent from planet Y has arrived with battle
 *             at planet z and is victorious with W ships surviving
 *           fleet with X ships sent from planet Y has arrived with battle
 *             at planet z and was defeated

 *          your planet X was attacked by player Y with Z ships, W ships remain
 *          your planet X was attacked by player Y with Z ships, and was captured
