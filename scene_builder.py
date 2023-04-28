import streamlit as st
from sqlalchemy.engine import URL, create_engine
from sqlalchemy.orm import Session
from sqlalchemy.orm.exc import NoResultFound, MultipleResultsFound
from sqlalchemy.sql import text
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
        qstring = "Select InitializeGame(" + pString + "," + numPlants + "," + mapWidth + "," + mapHeight + ")"
        dbcon.execute(text(qstring))
        dbcon.commit()
        st.session_state.scene="mainmenu"
    return HostButton

def CreateHostFunc():
    st.session_state.scene="host"

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
        st.sidebar.button(label="Back")
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
    qstring = "Select * From PlayerGame Where PlayerName = 'roland';"
    scene.markdown("# Join Game List")
    dbcon.begin()
    qResult = dbcon.execute(text(qstring))
    dbcon.commit()
    if qResult.first is not None:
        st.table(qResult)
        st.button(label="Back",on_click=CreateMainMenuFunc)
    else:
        st.warning("No games active.")
        st.button(label="Back",on_click=CreateMainMenuFunc)

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
        case "quit":
            BuildQuit(scene)