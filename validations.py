import re

# Test
# username = 'karls.mundaray@realpage.com'
    
class IsValid:
    #Checks a username is an email address
    @classmethod
    def user_id(cls, username) -> bool:
        if re.search(r"^\w+\.?\w*@\w+\.\w{2,3}$", username.strip()):
            return True
        else:
            return False

# Test
# result = IsValid.user_id(username)
# print(result)

#   . any character except a newline
#   + 1 or more repetitions
#   ? 0 or 1 repetitions
#   {m,n} m-n repetitions range
#   \w word character… as well as numbers and the underscore
