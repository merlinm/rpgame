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

def CreateRejoinFunc():
    st.session_state.scene="rejoin"

def QuitButton():
    st.session_state.scene="quit"

def InitialBuild():
    if "scene" not in st.session_state:
        st.session_state.scene = "login"

def BuildLogin(scene, dbcon):
    scene.empty()
    with scene.container():
        st.markdown("# RP Game")
        loginName = st.text_input(label="Login Name")
        loginPassword = st.text_input(label="Password", type="password")
        st.button(label="Login",on_click=CreateLoginFunc(dbcon, scene, loginName, loginPassword))

def BuildMainMenu(scene, dbcon):
    scene.empty()
    col1, col2, col3, col4 = scene.columns(4)
    col1.button("Host Game")
    col2.button("Join Game")
    col3.button(label="Rejoin Game",on_click=CreateRejoinFunc)
    col4.button(label="Quit",on_click=QuitButton)

def BuildRejoin(scene, dbcon):
    scene.empty()
    qstring = "Select GameList ('" + st.session_state.player + "');"
    dbcon.begin()
    qResult = dbcon.execute(text(qstring))
    dbcon.commit()
    if qResult.first() is not None:
        st.dataframe(qResult)
        for row in qResult:
            row("asdf")
            st.button(label="Rejoin " + "asdf",on_click=CreateRejoinGameInstance)
    else:
        st.warning("No games active.")
        st.button(label="Back",on_click=CreateMainMenuFunc)



def BuildQuit(scene):
    scene.empty()
    with scene.container():
        st.text("Thank you for playing! You can now close the tab.")
        


def SceneChanger(scene, dbcon, newScene:str):
    match newScene:
        case "login":
            BuildLogin(scene, dbcon)
        case "mainmenu":
            BuildMainMenu(scene, dbcon)
        case "rejoin":
            BuildRejoin(scene, dbcon)
        case "quit":
            BuildQuit(scene)

