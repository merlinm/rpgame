import streamlit as st
#import pandas as pd
import asyncio as ac
#from sqlalchemy.engine import URL, create_engine
#from sqlalchemy.orm import Session
#from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound
from sqlalchemy.sql import text
#from sqlalchemy.dialects.postgresql import JSONB
#from validations import IsValid


def CreateHostFunc():
    st.session_state.scene = "host"

def CreateRejoinFunc():
    st.session_state.scene = "rejoin"

def QuitButton():
    st.session_state.scene = "login"

def InitialBuild():
    if "scene" not in st.session_state:
        st.session_state.scene = "login"

def BuildQuit(scene):
    st.text("Thank you for playing! You can now close the tab.")

def BuildLogin(scene, dbcon):
    with scene.container():
        st.markdown("# RP Game")
        loginName = st.text_input(label="Login Name")
        loginPassword = st.text_input(label="Password", type="password")
        st.button(label="Login",on_click=CreateLoginFunc(dbcon, scene, loginName, loginPassword))

def SceneChanger(scene, dbcon, newScene:str):
    scene.empty()
    match newScene:
        case "login":
            BuildLogin(scene, dbcon)
        case "mainmenu":
            BuildMainMenu(scene, dbcon)
        case "host":
            BuildHost(scene, dbcon)
        case "rejoin":
            BuildRejoin(scene, dbcon)
        case "playgame":
            BuildPlayGame(scene, dbcon)
        case "quit":
            BuildLogin(scene, dbcon)

# Login page
def CreateLoginFunc(dbcon, scene, loginName, loginPassword):
    def LoginButton():
        if loginName != "" and loginPassword != "":
            dbcon.begin()
            qstring = "Select LoginPlayer (:loginName, :loginPassword);"
            loginPlayerResult = dbcon.execute(text(qstring), {"loginName": loginName, "loginPassword": loginPassword})
            # loginPlayerResult contains a tuple with true or false flags. 
            # One for successful login and another to identify if a new user was created.
            loginPlayerTest = loginPlayerResult.all()
            dbcon.commit()
            if loginPlayerTest[0][0][1] == 't':
                if loginPlayerTest[0][0][3] == 't':
                    st.warning(f"User {loginName} was created.")
                with scene.container():
                    st.session_state.scene = "mainmenu"
                    st.session_state.player = loginName
            else:
                st.warning(f"Incorrect username or password provided.")
                return LoginButton
        else:
            st.warning("Username and/or password are missing.")
    return LoginButton

def CreateMainMenuFunc():
    # if "currentGameId" not in st.session_state:
    #     st.session_state.currentGameId = 0
    #     st.session_state.currentGameTurn = 0
    st.session_state.currentGameId = 0
    st.session_state.currentGameTurn = 0
    st.session_state.scene="mainmenu"

# Initializes the game from Host Game page
def CreateHostButtonFunc(dbcon, scene, mapHeight, mapWidth, numPlants, playerlist):
    # def HostButton():
    pString = "["
    for p in playerlist:
        if p == "":
            playerlist.remove(p)
        elif playerlist.index(p) == len(playerlist) - 1:
            pString += p + "]"
        else:
            pString += p + ","
    dbcon.begin()
    qstring = f"Call InitializeGame(array{playerlist}, {numPlants}, {mapWidth}, {mapHeight});"
    dbcon.execute(text(qstring))
    dbcon.commit()
    # return HostButton

# Rejoin button in main menu
def CreateRejoinButtonFunc(gameId):
    if "currentGameId" not in st.session_state:
        st.session_state.currentGameId = gameId
        st.session_state.currentGameTurn = 0
    st.session_state.currentGameId = gameId
    st.session_state.scene = "playgame"

# Host game page
def BuildHost(scene, dbcon):
    with st.sidebar:
        st.button(label="Back",on_click=CreateMainMenuFunc)
        st.button(label="Quit", on_click = QuitButton)
    with st.container():
        st.markdown("# Host Game")
        with st.form("host_details"):
            mapHeight = st.text_input(label="Map height",value=20)
            mapWidth = st.text_input(label="Map width",value=20)
            numPlants = st.text_input(label="Number of planets",value=30)
            player1 = st.text_input(label="Player 1",value=st.session_state.player,disabled=True)
            player2 = st.text_input(label="Player 2")
            player3 = st.text_input(label="Player 3")
            player4 = st.text_input(label="Player 4")
            submitted = st.form_submit_button("Start Game")
            if submitted:
                CreateHostButtonFunc(dbcon, scene, mapHeight, mapWidth, numPlants, [player1, player2, player3, player4])
                st.session_state.scene = "rejoin"

def BuildMainMenu(scene, dbcon):
    col1, col2, col3 = scene.columns(3)
    col1.button(label="Host Game",on_click=CreateHostFunc)
    col2.button(label="Rejoin Game",on_click=CreateRejoinFunc)
    col3.button(label="Quit",on_click=QuitButton)

# Rejoin page
def BuildRejoin(scene, dbcon):
    dbcon.begin()
    qstring = f"SELECT gameid FROM PlayerGame WHERE PlayerName = '{st.session_state.player}';"
    qResult = dbcon.execute(text(qstring))
    dbcon.commit()
    avail_game_ids = qResult.scalars().all()
    if len(avail_game_ids) != 0:
        lastGameId = avail_game_ids[-1]
        noGames = False
    else:
        lastGameId = "No games available"
        noGames = True
    with st.form("join_game_id"):
        gameId = st.text_input(label="Game ID", 
                               max_chars = 10, 
                               placeholder = f"Last Game ID: {lastGameId}", 
                               value = lastGameId, # Defaults to latest game
                               disabled = noGames)
        submitted = st.form_submit_button(f"Join Game")
        if submitted:
            CreateRejoinButtonFunc(gameId)
    with st.sidebar:
        st.button(label="Back",on_click=CreateMainMenuFunc)
        st.button(label="Quit",on_click=QuitButton)
    with st.container():
        scene.markdown(f"# Avalable games for player {st.session_state.player}")
        qstring = "Select gameid as \"Game ID\", commandsdone as \"Turn Completed\" From PlayerGame Where PlayerName = '" + st.session_state.player + "';"
        dbcon.begin()
        qResult = dbcon.execute(text(qstring))
        dbcon.commit()
        if qResult.rowcount != 0:
            st.table(qResult.mappings().all())
            hide_table_row_index = """
                <style>
                thead tr th:first-child {display:none}
                tbody th {display:none}
                </style>
                """
            st.markdown(hide_table_row_index, unsafe_allow_html=True)
        else:
            st.warning("No games active.")

def BuildPlayGame(scene, dbcon):
    st.sidebar.header(f"Player: {st.session_state.player}")
    st.sidebar.write(f"Game ID: {st.session_state.currentGameId}")
    infotab, commandtab, historytab = st.tabs(["Game Board", "Send Commands", "Battle Log"])
    with st.sidebar:
        with st.form("enter_commands", clear_on_submit=True):
            sourceP = st.text_input(label="Source Planet")
            destP = st.text_input(label="Destination Planet")
            fleetSize = st.text_input(label="Fleet Size")
            submitted = st.form_submit_button("Send Ships")
            if submitted:
                with dbcon.begin():  # This will automatically commit or rollback the transaction
                    qString = f"Select AddCommand('{st.session_state.player}','{sourceP}','{destP}','{fleetSize}','{st.session_state.currentGameId}');"
                    dbcon.execute(text(qString))
                st.experimental_rerun()
        if st.sidebar.button(label="Finish Turn",type="primary"):
            with dbcon.begin():  # This will automatically commit or rollback the transaction
                qString = f"Select CommandsDone('{st.session_state.player}','{st.session_state.currentGameId}');"
                dbcon.execute(text(qString))
        st.sidebar.button(label="Back", on_click = CreateRejoinFunc)
        st.sidebar.button(label="Quit", on_click = QuitButton)
    with infotab:
        ph = st.empty()
        ph.empty()
    with commandtab:
        st.empty()
    with historytab:
        ht = st.empty()
        ht.empty()
    ac.run(UpdatePlayGame(dbcon, infotab, ph, commandtab, historytab, ht, st.session_state.currentGameId, st.session_state.player))

async def UpdatePlayGame(dbcon, infotab, ph, commandtab, historytab, ht, gameId, player):
    GameTurn = st.session_state.currentGameTurn
    while gameId != 0:
        qstring = f"Select Turn From Game Where GameId = {gameId};"
        with dbcon.begin():  # This will automatically commit or rollback the transaction
            qResult = dbcon.execute(text(qstring))
        turnResult = qResult.scalar()
        st.session_state.currentGameTurn = turnResult
        turnChanged = GameTurn != turnResult
        if turnChanged:
            GameTurn = turnResult
            ph.empty()
        with ph.container():
            mapCol, planetsCol = st.columns(2)
            with mapCol:
                st.write(f"Turn: {str(turnResult)}")
                qstring = f"SELECT ShowMap('{player}', {gameId});"
                with dbcon.begin():  # This will automatically commit or rollback the transaction
                    qResult = dbcon.execute(text(qstring))
                mapdisplaystring = ""
                for r in qResult.scalars():
                    mapdisplaystring += r + "\n"
                st.text(mapdisplaystring)
            with planetsCol:
                qstring = f"SELECT ShowPlanetList('{player}', {gameId});"
                with dbcon.begin():  # This will automatically commit or rollback the transaction
                    qResult = dbcon.execute(text(qstring))
                restable = [row._asdict() for row in qResult.all()]
                parsetable = restable[0]["showplanetlist"]
                hide_table_row_index = """
                    <style>
                    thead tr th:first-child {display:none}
                    tbody th {display:none}
                    </style>
                    """
                st.markdown(hide_table_row_index, unsafe_allow_html=True)
                st.table(parsetable)
        with commandtab:
            st.empty()
        with historytab:
            st.empty()
        with infotab:
            with ht.container():
                qstring = f"SELECT battles({gameId}, '{player}');"
                with dbcon.begin():  # This will automatically commit or rollback the transaction
                    qResult = dbcon.execute(text(qstring))
                battlelog = ""
                for r in qResult.scalars():
                    battlelog += r + "\n"
                print(battlelog, len(battlelog))
                if len(battlelog) < 1:
                    st.warning("No logs available for this game.")
                st.text(battlelog)
    await ac.sleep(3)

