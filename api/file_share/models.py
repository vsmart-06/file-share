from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
import datetime
import random as rd

class UserManager(BaseUserManager):
    def create_user(self, username, email, password, **kwargs):
        if not username:
            raise ValueError("'username' field is required")
        if not email:
            raise ValueError("'email' field is required")
        if not password:
            raise ValueError("'password' field is required")

        email = self.normalize_email(email)
        email.lower()

        while True:
            try:
                code = rd.randint(100000, 999999)
                self.get(code = code)
            except:
                break

        user: UserCredentials = self.model(username = username, email = email, time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), code = code, **kwargs)
        user.set_password(password)

        try:
            user.save(using = self._db)
        except:
            raise Exception("A user with that email already exists")

        return user
    
    def create_superuser(self, username, email, password, **kwargs):
        kwargs.setdefault("is_staff", True)
        kwargs.setdefault("is_superuser", True)
        return self.create_user(username, email, password, **kwargs)


class UserCredentials(AbstractBaseUser, PermissionsMixin):
    user_id = models.AutoField(primary_key = True, unique = True, null = False)
    username = models.TextField(unique = True, null = False)
    email = models.EmailField(unique = True, null = False)
    code = models.TextField(unique = True, null = True)
    time = models.TextField(unique = False, null = True)
    verified = models.BooleanField(default = False, null = False)
    is_staff = models.BooleanField(default = False, null = False)

    USERNAME_FIELD = "username"

    objects: UserManager = UserManager()