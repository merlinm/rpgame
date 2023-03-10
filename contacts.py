from asciimatics.widgets import Frame, ListBox, Layout, Divider, Text, \
    Button, TextBox, Widget
from asciimatics.scene import Scene
from asciimatics.screen import Screen
from asciimatics.exceptions import ResizeScreenError, NextScene, StopApplication
import sys
import sqlite3
from sqlalchemy.engine import URL, create_engine

#_________________________Database Engine________________________#
connection_url = URL.create(
    "postgresql+psycopg2",
    username="student",
    password="rpstudent",
    host="rpgame.mooo.com",
    database="student"
    )

engine = create_engine(connection_url)

#_______________________UI Database Model______________________#
class ContactModel(object):
    def __init__(self):
        # Create a database in RAM.
        self._db = sqlite3.connect(':memory:')
        self._db.row_factory = sqlite3.Row

        # Create the basic players table.
        self._db.cursor().execute('''
            CREATE TABLE players(
                username TEXT PRIMARY KEY,
                game_id INTEGER)
        ''')
        self._db.commit()

        # Current player when editing.
        self.current_id = None

    def add(self, player):
        self._db.cursor().execute('''
            INSERT INTO players(username)
            VALUES(:username)''',
            player) 
        self._db.commit()

    def get_summary(self):
        return self._db.cursor().execute(
            "SELECT username, game_id from players").fetchall()

    def get_player(self, username):
        return self._db.cursor().execute(
            "SELECT * from players WHERE username=:username", {"username": username}).fetchone()

    def get_current_player(self):
        if self.current_id is None:
            return {"username": "", "password": ""}
        else:
            return self.get_player(self.current_id)

    def update_current_player(self, details):
        if self.current_id is None:
            self.add(details)
        else:
            self._db.cursor().execute('''
                UPDATE players SET username=:username, password=:password WHERE username=:username''',
                details)
            self._db.commit()

    def delete_player(self, username):
        self._db.cursor().execute('''
            DELETE FROM players WHERE username=:username''', {"id": username})
        self._db.commit()


#_________________________Login Page________________________#
class LoginView(Frame):
    def __init__(self, screen, model):
        super(LoginView, self).__init__(screen,
                                       screen.height * 2 // 3,
                                       screen.width * 2 // 3,
                                       hover_focus=True,
                                       can_scroll=False,
                                       title="RealPage Game")
        # Save off the model that accesses the contacts database.
        self._model = model                                                ##### REMOVE MODEL IF IT DOESNT BREAK IT

        # Create the form for displaying the list of contacts.   # Have to switch to list of games
        self._list_view = ListBox(
            Widget.FILL_FRAME,
            model.get_summary(),
            name="players",
            add_scroll_bar=True)                                    ##### REMOVE MODEL WITHOUT BREAKING IT

        layout = Layout([100], fill_frame=True)
        self.add_layout(layout)
        layout.add_widget(Text("Username:", "username"))    # Type Username to log in 
        layout.add_widget(Text("Password:", "password"))    # Type Password to log in
        layout.add_widget(self._list_view)
        layout.add_widget(Divider())
        layout2 = Layout([1, 1, 1, 1])
        self.add_layout(layout2)
        layout2.add_widget(Button("Log in", self._log_in), 0)
        layout2.add_widget(Button("Exit", self._exit), 3)
        self.fix()

# Need to get rid of the model

    def _log_in(self):
        self.save()
        with engine.connect() as connection:
            result = connection.execute(
                f"SELECT * FROM player WHERE playername = '{self.data['username']}' AND password_raw = '{self.data['password']}';"
                )
            if len(result.all()) == 0:
                connection.execute(
                f"INSERT INTO PLAYER (playername, password_raw) VALUES ('{self.data['username']}', '{self.data['password']}');"
                )
        raise NextScene("Main")
    
    def reset(self):
        # Do standard reset to clear out form
        super(LoginView, self).reset()

    @staticmethod
    def _exit():
        raise StopApplication("User pressed quit")


#_________________________Landing Page________________________#
class ListView(Frame):
    def __init__(self, screen, model):
        super(ListView, self).__init__(screen,
                                       screen.height * 2 // 3,
                                       screen.width * 2 // 3,
                                       on_load=self._reload_list,
                                       hover_focus=True,
                                       can_scroll=False,
                                       title="RealPage Game")
        # Save off the model that accesses the contacts database.
        self._model = model

        # Create the form for displaying the list of contacts.   # Have to switch to list of games
        self._list_view = ListBox(
            Widget.FILL_FRAME,
            model.get_summary(),
            name="contacts",
            add_scroll_bar=True,
            on_change=self._on_pick,
            on_select=self._join)

        self._join_button = Button("Join", self._join)
        self._return_button = Button("Return", self._return)
        layout = Layout([100], fill_frame=True)
        self.add_layout(layout)
        layout.add_widget(self._list_view)
        layout.add_widget(Divider())
        layout2 = Layout([1, 1, 1, 1])
        self.add_layout(layout2)
        layout2.add_widget(Button("Create", self._create), 0)
        layout2.add_widget(self._join_button, 1)
        layout2.add_widget(self._return_button, 2)
        layout2.add_widget(Button("Exit", self._exit), 3)
        self.fix()
        self._on_pick()

    def _on_pick(self):
        self._join_button.disabled = self._list_view.value is None
        self._return_button.disabled = self._list_view.value is None

    def _reload_list(self, new_value=None):
        self._list_view.options = self._model.get_summary()
        self._list_view.value = new_value

    def _create(self):
        self._model.current_id = None
        raise NextScene("Edit Contact")

    def _join(self):
        self.save()
        self._model.current_id = self.data["contacts"]
        raise NextScene("Edit Contact")

    def _return(self):
        self.save()
        self._model.delete_contact(self.data["contacts"])
        self._reload_list()
        # raise NextScene("Return to Game")

    @staticmethod
    def _exit():
        raise StopApplication("User pressed quit")


class ContactView(Frame):
    def __init__(self, screen, model):
        super(ContactView, self).__init__(screen,
                                          screen.height * 2 // 3,
                                          screen.width * 2 // 3,
                                          hover_focus=True,
                                          can_scroll=False,
                                          title="Contact Details",
                                          reduce_cpu=True)
        # Save off the model that accesses the contacts database.
        self._model = model

        # Create the form for displaying the list of contacts.
        layout = Layout([100], fill_frame=True)
        self.add_layout(layout)
        layout.add_widget(Text("Name:", "name"))
        layout.add_widget(Text("Address:", "address"))
        layout.add_widget(Text("Phone number:", "phone"))
        layout.add_widget(Text("Email address:", "email"))
        layout.add_widget(TextBox(
            Widget.FILL_FRAME, "Notes:", "notes", as_string=True, line_wrap=True))
        layout2 = Layout([1, 1, 1, 1])
        self.add_layout(layout2)
        layout2.add_widget(Button("OK", self._ok), 0)
        layout2.add_widget(Button("Cancel", self._cancel), 3)
        self.fix()

    def reset(self):
        # Do standard reset to clear out form, then populate with new data.
        super(ContactView, self).reset()
        self.data = self._model.get_current_contact()

    def _ok(self):
        self.save()
        self._model.update_current_contact(self.data)
        raise NextScene("Main")

    @staticmethod
    def _cancel():
        raise NextScene("Main")

#____________ Starts the Game _______________#
# Login view, game selection, game view
def game(screen, scene):
    scenes = [
        Scene([LoginView(screen, contacts)], -1, name="Login"),
        Scene([ListView(screen, contacts)], -1, name="Main"),
        Scene([ContactView(screen, contacts)], -1, name="Edit Contact")
    ]

    screen.play(scenes, stop_on_resize=True, start_scene=scene, allow_int=True)


contacts = ContactModel()
last_scene = None
while True:
    try:
        Screen.wrapper(game, catch_interrupt=True, arguments=[last_scene])
        sys.exit(0)
    except ResizeScreenError as e:
        last_scene = e.scene