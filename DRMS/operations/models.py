from django.db import models
from django.core.validators import MinValueValidator

class Donation(models.Model):
    DONOR_TYPE_CHOICES = [
        ('individual', 'Individual'),
        ('organization', 'Organization'),
    ]
    id = models.AutoField(primary_key=True)
    donor_name = models.CharField(max_length=200)
    donor_type = models.CharField(max_length=20, choices=DONOR_TYPE_CHOICES)
    contact_email = models.EmailField(blank=True)
    contact_phone = models.CharField(max_length=15, blank=True)
    donation_date = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    
    class Meta:
        db_table = 'donations'
        indexes = [
            models.Index(fields=['donor_type', 'donation_date']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(donor_type__in=['individual', 'organization']),
                name='valid_donor_type'
            )
        ]

    def __str__(self):
        return f"{self.donor_name} - {self.donation_date.date()}"

class DonationItem(models.Model):
    id = models.AutoField(primary_key=True)
    donation = models.ForeignKey(Donation, on_delete=models.CASCADE, related_name='items')
    resource = models.ForeignKey('relief.Resource', on_delete=models.SET_NULL, null=True)
    quantity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.01)])
    
    class Meta:
        db_table = 'donation_items'
        indexes = [
            models.Index(fields=['resource']),
        ]

    def __str__(self):
        return f"{self.quantity} x {self.resource.name} from {self.donation.donor_name}"

class DonationAcknowledgment(models.Model):
    id = models.AutoField(primary_key=True)
    donation = models.OneToOneField(Donation, on_delete=models.CASCADE)
    acknowledgment_text = models.TextField()
    acknowledged_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    acknowledged_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'donation_acknowledgments'

    def __str__(self):
        return f"Acknowledgment for {self.donation.donor_name}"

class Transport(models.Model):
    TRANSPORT_TYPE_CHOICES = [
        ('truck', 'Truck'),
        ('van', 'Van'),
        ('boat', 'Boat'),
        ('helicopter', 'Helicopter'),
        ('other', 'Other'),
    ]
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('in_use', 'In Use'),
        ('maintenance', 'Maintenance'),
        ('unavailable', 'Unavailable'),
    ]
    id = models.AutoField(primary_key=True)
    vehicle_number = models.CharField(max_length=50, unique=True)
    transport_type = models.CharField(max_length=20, choices=TRANSPORT_TYPE_CHOICES)
    capacity = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.01)])
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    assigned_to_camp = models.ForeignKey('shelters.Camp', on_delete=models.SET_NULL, null=True, blank=True)
    last_service_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'transports'
        indexes = [
            models.Index(fields=['transport_type', 'status']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(transport_type__in=['truck', 'van', 'boat', 'helicopter', 'other']),
                name='valid_transport_type'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['available', 'in_use', 'maintenance', 'unavailable']),
                name='valid_transport_status'
            )
        ]

    def __str__(self):
        return f"{self.transport_type} ({self.vehicle_number})"

class HelpRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('cancelled', 'Cancelled'),
    ]
    id = models.AutoField(primary_key=True)
    victim = models.ForeignKey('users.User', on_delete=models.CASCADE, limit_choices_to={'role':'victim'})
    disasters = models.ForeignKey('disasters.Disasters', on_delete=models.CASCADE)
    description = models.TextField()
    location = models.CharField(max_length=255)
    requested_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    class Meta:
        db_table = 'help_requests'
        indexes = [
            models.Index(fields=['status', 'requested_at']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(status__in=['pending', 'in_progress', 'resolved', 'cancelled']),
                name='valid_help_status'
            )
        ]

    def __str__(self):
        return f"HelpRequest by {self.victim.username} - {self.status}"

class TaskAssignment(models.Model):
    STATUS_CHOICES = [
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    id = models.AutoField(primary_key=True)
    volunteer = models.ForeignKey('users.User', on_delete=models.CASCADE, limit_choices_to={'role':'volunteer'})
    task_description = models.TextField()
    help_request = models.ForeignKey(HelpRequest, on_delete=models.CASCADE, null=True, blank=True)
    assigned_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='assigned')

    class Meta:
        db_table = 'task_assignments'
        indexes = [
            models.Index(fields=['status', 'assigned_at']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(status__in=['assigned', 'in_progress', 'completed', 'cancelled']),
                name='valid_task_status'
            )
        ]

    def __str__(self):
        return f"{self.task_description[:30]}... - {self.volunteer.username}"