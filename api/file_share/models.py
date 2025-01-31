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

        user: UserCredentials = self.model(username = username, email = email, timestamp = datetime.datetime.now(tz = datetime.timezone.utc), code = code, **kwargs)
        user.set_password(password)

        try:
            user.save(using = self._db)
        except:
            raise Exception("A user with that username or email already exists")

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
    timestamp = models.DateTimeField(unique = False, null = True)
    verified = models.BooleanField(default = False, null = False)
    is_staff = models.BooleanField(default = False, null = False)

    USERNAME_FIELD = "username"

    objects: UserManager = UserManager()


class UserDevices(models.Model):
    device_id = models.AutoField(primary_key = True, unique = True, null = False)
    identifier = models.TextField(unique = False, null = False)
    name = models.TextField(unique = False, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user", on_delete = models.CASCADE, null = False)
    platform = models.TextField(choices = [("ios", "ios"), ("android", "android"), ("windows", "windows"), ("macos", "macos"), ("linux", "linux")])


class UserContacts(models.Model):
    contact_id = models.AutoField(primary_key = True, unique = True, null = False)
    first = models.ForeignKey(UserCredentials, related_name = "first", on_delete = models.CASCADE, null = False)
    second = models.ForeignKey(UserCredentials, related_name = "second", on_delete = models.CASCADE, null = False)
    approved = models.BooleanField(default = False, null = False)


class SharedDocuments(models.Model):
    document_id = models.AutoField(primary_key = True, unique = True, null = False)
    sender_device = models.ForeignKey(UserDevices, related_name = "sender_device", on_delete = models.CASCADE, null = False)
    sender_contact = models.ForeignKey(UserCredentials, related_name = "sender_contact", on_delete = models.CASCADE, null = False)
    recipient_device = models.ForeignKey(UserDevices, related_name = "receiver_device", on_delete = models.CASCADE, null = True)
    recipient_contact = models.ForeignKey(UserCredentials, related_name = "receiver_contact", on_delete = models.CASCADE, null = True)
    data = models.JSONField(unique = False, null = False)
    opened = models.BooleanField(unique = False, default = False, null = False)
    timestamp = models.DateTimeField(unique = False, null = False)