# Generated by Django 5.1.2 on 2025-01-10 13:20

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('file_share', '0006_userdevices_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='usercontacts',
            name='approved',
            field=models.BooleanField(default=False),
        ),
    ]
