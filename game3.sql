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
 * Hopefully we were all able to get github installed, desktop with project set
 * up
 *
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
 * Game intialization  (Take a list of payers)
 *   Verify at least 2 players
 *   Generate playfield
 *   Insert game record
 * Turn/phase processing
 * Processing commands into fleets (function / procedure)
 *   Distance function
 * Process fleets in transit
 * Battles, ship to planet combat
 *  Dice roller
 *
 * Playfield display function
 * welcome new people
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


  Defence INT,

  Ships INT,
  
  XPosition INT,
  YPosition INT,
  
  FOREIGN KEY(GameId, Owner) REFERENCES PlayerGame(GameId, PlayerName)
   ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE(GameId, XPosition, YPosition)
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
  PRIMARY KEY(PlayerName, SourcePlanetId, DestinationPlanetId)
);


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
          Defence,
          Ships,
          XPosition,
          YPosition)
        VALUES (
          DEFAULT,
          _GameId,
          NULL,
          DiceRoller(0, 11, 1), 
          DiceRoller(5, 20, 1),
          0,
          DiceRoller(_PlayFieldWidth, 1),
          DiceRoller(_PlayFieldHeight, 1));
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



 


