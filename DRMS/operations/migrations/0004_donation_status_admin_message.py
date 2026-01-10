# Generated manually for adding status and admin_message fields to Donation model

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('operations', '0003_transport_current_location_helprequeststatushistory_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='donation',
            name='status',
            field=models.CharField(
                choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')],
                default='pending',
                max_length=20
            ),
        ),
        migrations.AddField(
            model_name='donation',
            name='admin_message',
            field=models.TextField(blank=True, help_text='Message from camp admin', null=True),
        ),
        migrations.AddIndex(
            model_name='donation',
            index=models.Index(fields=['created_by', 'status'], name='donations_created_status_idx'),
        ),
        migrations.AddConstraint(
            model_name='donation',
            constraint=models.CheckConstraint(
                check=models.Q(status__in=['pending', 'approved', 'rejected']),
                name='valid_donation_status'
            ),
        ),
    ]

