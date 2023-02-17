# https://docs.sqlalchemy.org/en/20/core/engines.html
from sqlalchemy.engine import URL, create_engine
# from sqlalchemy.sql import table, column, select
from sqlalchemy import text

def main():

    connection_url = URL.create(
    "postgresql+psycopg2",
    username="student",
    password="rpstudent",
    host="rpgame.mooo.com",
    database="student"
    )

    engine = create_engine(connection_url)

    with engine.connect() as connection:
        result = connection.execute(
            text("select * from command;"))
        for each in result:
            print(each)
    
    print("Success!")


if __name__ == "__main__":
    main()