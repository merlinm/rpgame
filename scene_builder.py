import streamlit as st
import pandas as pd
from sqlalchemy.engine import URL, create_engine
from sqlalchemy.orm import Session
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound
from sqlalchemy.sql import text
from sqlalchemy.dialects.postgresql import JSONB
import sys

def CreateLoginFunc(dbcon, scene, loginName, loginPassword):
    def LoginButton():
        if loginName != "" and loginPassword != "":
            dbcon.begin()
            qstring = "Select LoginPlayer ('" + loginName + "','" + loginPassword + "');"
            loginResult = dbcon.execute(text(qstring))
            dbcon.commit()
            if loginResult.first:
                with scene.container():
                    st.session_state.scene="mainmenu"
                    st.session_state.player = loginName
        else:
            st.warning("Username and/or password missing.")
    return LoginButton

def CreateMainMenuFunc():
    st.session_state.scene="mainmenu"

def CreateHostButtonFunc(dbcon, scene, mapHeight, mapWidth, numPlants, playerlist):
    def HostButton():
        pString = "{"
        for p in playerlist:
            if p == "":
                playerlist.remove(p)
            elif playerlist.index(p) == len(playerlist) - 1:
                pString += p + "}"
            else:
                pString += p + ","
        
        dbcon.begin()
        qstring = "Call InitializeGame(" + pString + "," + numPlants + "," + mapWidth + "," + mapHeight + ")"
        dbcon.execute(text(qstring))
        dbcon.commit()
        st.session_state.scene="mainmenu"
    return HostButton

def CreateHostFunc():
    #st.session_state.scene="host"
    st.session_state.scene="playgame"

def CreateRejoinFunc():
    st.session_state.scene="rejoin"

def QuitButton():
    st.session_state.scene="quit"

def InitialBuild():
    if "scene" not in st.session_state:
        st.session_state.scene = "login"

def BuildLogin(scene, dbcon):
    with scene.container():
        st.markdown("# RP Game")
        loginName = st.text_input(label="Login Name")
        loginPassword = st.text_input(label="Password", type="password")
        st.button(label="Login",on_click=CreateLoginFunc(dbcon, scene, loginName, loginPassword))

def BuildHost(scene, dbcon):
    with st.sidebar:
        mapHeight = st.sidebar.text_input(label="Map height",value=20)
        mapWidth = st.sidebar.text_input(label="Map width",value=20)
        numPlants = st.sidebar.text_input(label="Number of planets",value=30)
        st.sidebar.button(label="Back",on_click=CreateMainMenuFunc)
    with st.container():
        st.markdown("# Host Game")
        player1 = st.text_input(label="Player 1",value=st.session_state.player,disabled=True)
        player2 = st.text_input(label="Player 2")
        player3 = st.text_input(label="Player 3")
        player4 = st.text_input(label="Player 4")
        st.button(label="Host Game",on_click=CreateHostButtonFunc(dbcon, scene, mapHeight, mapWidth, numPlants, [player1, player2, player3, player4]))

def BuildMainMenu(scene, dbcon):
    col1, col2, col3, col4 = scene.columns(4)
    col1.button(label="Host Game",on_click=CreateHostFunc)
    col2.button("Join Game")
    col3.button(label="Rejoin Game",on_click=CreateRejoinFunc)
    col4.button(label="Quit",on_click=QuitButton)
 
def BuildRejoin(scene, dbcon):
    scene.markdown("# Join Game List")
    qstring = "Select * From PlayerGame Where PlayerName = '" + st.session_state.player +"';"
    dbcon.begin()
    qResult = dbcon.execute(text(qstring))
    dbcon.commit()
    if qResult.first is not None:
        st.table(qResult)
        st.button(label="Back",on_click=CreateMainMenuFunc)
    else:
        st.warning("No games active.")
        st.button(label="Back",on_click=CreateMainMenuFunc)

def BuildPlayGame(scene, dbcon):
    #qstring = "Select * From PlayerGame Where PlayerName = '" + st.session_state.player +"';"
    #dbcon.begin()
    #qResult = dbcon.execute(text(qstring))
    #dbcon.commit()
    st.header(st.session_state.player + " - Game ID: " + "")
    maptab, planettab, commandtab, historytab = st.tabs(["Map", "Planets", "Commands", "Battle Log"])
    with st.sidebar:
        st.button(label="Finish Turn", type = "primary")
        sourceP = st.text_input(label="Source Planet")
        destP = st.text_input(label="Destination Planet")
        fleetSize = st.text_input(label="Fleet Size")
        st.button(label="Send Ships")
        #qstring = "Select ShowPlanetList('roland', 4);"
        #dbcon.begin()
        #qResult = dbcon.execute(text(qstring))
        #dbcon.commit()
        #restable = [row._asdict() for row in qResult.all()]
        #makemeatable = restable[0]["showplanetlist"]
        #planetnames = st.sidebar.dataframe(makemeatable)
        #st.button(label="Back",on_click=CreateMainMenuFunc)
    with maptab:
        #qstring = "Select ShowMap('" + st.session_state.player +"', " + st.session_state.currentGameID + ");"
        mapCol, planetsCol = st.columns(2)
        with mapCol:
            qstring = "Select ShowMap('roland', 4);"
            dbcon.begin()
            qResult = dbcon.execute(text(qstring))
            dbcon.commit()
            mapdisplaystring = ""
            for r in qResult.scalars():
                mapdisplaystring += r + "\n"
            mapdisplay = st.text(mapdisplaystring)
        with planetsCol:
            qstring = "Select ShowPlanetList('roland', 4);"
            dbcon.begin()
            qResult = dbcon.execute(text(qstring))
            dbcon.commit()
            restable = [row._asdict() for row in qResult.all()]
            makemeatable = restable[0]["showplanetlist"]
            hide_table_row_index = """
                <style>
                thead tr th:first-child {display:none}
                tbody th {display:none}
                </style>
                """
            st.markdown(hide_table_row_index, unsafe_allow_html=True)
            planetdisplay = st.table(makemeatable)
    with planettab:
        #qstring = "Select ShowPlanetList('" + st.session_state.player +"', " + st.session_state.currentGameID + ");"
        qstring = "Select ShowPlanetList('roland', 4);"
        dbcon.begin()
        qResult = dbcon.execute(text(qstring))
        dbcon.commit()
        #df = pd.read_json(qResult)
        #pddf = pd.DataFrame(qResult.all())
        #pddf.columns = qResult.keys()
        #asdf = st.text([type(t) for t in qResult.all()])
        #planetdisplay = st.json(qResult.all())
        #planetdisplay = st.dataframe(row.all() for row in qResult.all())
        #tabledict = dict()
        
        #restable = [[getattr(row, col.name) for col in row.__table__.columns] for row in  qResult.all()]
        restable = [row._asdict() for row in qResult.all()]
        makemeatable = restable[0]["showplanetlist"]
        hide_table_row_index = """
            <style>
            thead tr th:first-child {display:none}
            tbody th {display:none}
            </style>
            """
        st.markdown(hide_table_row_index, unsafe_allow_html=True)
        planetdisplay = st.table(makemeatable)
        #planetdisplay = st.text(restable)
        #asdf = st.text(type("asd"))
    with commandtab:
        a = 1
        #st.button(label="Finish Turn", type = "primary")
        #sourceP = st.text_input(label="Source Planet")
        #destP = st.text_input(label="Destination Planet")
        #fleetSize = st.text_input(label="Fleet Size")
        #st.button(label="Send Ships")
    with historytab:
        col1, col2 = st.columns(2)
        col1.write("column 1")
        col2.write("column 2")



def BuildQuit(scene):
    st.text("Thank you for playing! You can now close the tab.")


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
            BuildQuit(scene)
