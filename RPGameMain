import streamlit as st
from sqlalchemy.engine import URL, create_engine
from sqlalchemy.orm import Session
from sqlalchemy.sql import text
import sys
import scene_builder

scene = st.empty()

connection_url = URL.create(
    "postgresql+psycopg2",
    username="student",
    password="rpstudent",
    host="rpgame.mooo.com",
    database="student"
    )

engine = create_engine(connection_url)

dbcon = Session(engine)

scene_builder.InitialBuild()

scene_builder.SceneChanger(scene, dbcon, st.session_state.scene)