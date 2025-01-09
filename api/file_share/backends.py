from django.contrib.auth.backends import ModelBackend
from file_share.models import UserCredentials

class UserCredentialsBackend(ModelBackend):
    def authenticate(self, request, username, password, **kwargs):
        if not username or not password:
            return ValueError("Neither 'username' nor 'password' can be null")
        
        try:
            user: UserCredentials = UserCredentials.objects.get(email = username if "@" in username else None, username = username if "@" not in username else None)
            if user.check_password(password):
                return user
            
        except UserCredentials.DoesNotExist:
            return None