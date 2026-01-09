from django.db import models
from django.core.validators import MinValueValidator, MinLengthValidator

class Resource(models.Model):
    CATEGORY_CHOICES = [
        ('food', 'Food'),
        ('water', 'Water'),
        ('medical', 'Medical Supplies'),
        ('clothing', 'Clothing'),
        ('shelter', 'Shelter Materials'),
        ('hygiene', 'Hygiene Kits'),
        ('equipment', 'Equipment'),
        ('other', 'Other'),
    ]
    UNIT_CHOICES = [
        ('kg', 'Kilogram'),
        ('g', 'Gram'),
        ('l', 'Liter'),
        ('ml', 'Milliliter'),
        ('piece', 'Piece'),
        ('box', 'Box'),
        ('pack', 'Pack'),
        ('unit', 'Unit'),
    ]

    id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=200, validators=[MinLengthValidator(2)])
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    description = models.TextField(blank=True)
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES)
    total_quantity = models.DecimalField(max_digits=12, decimal_places=2, default=0, validators=[MinValueValidator(0)])
    available_quantity = models.DecimalField(max_digits=12, decimal_places=2, default=0, validators=[MinValueValidator(0)])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'resources'
        indexes = [
            models.Index(fields=['category', 'is_active']),
            models.Index(fields=['is_active']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(category__in=['food', 'water', 'medical', 'clothing', 'shelter', 'hygiene', 'equipment', 'other']),
                name='valid_resource_category'
            ),
            models.CheckConstraint(
                check=models.Q(unit__in=['kg', 'g', 'l', 'ml', 'piece', 'box', 'pack', 'unit']),
                name='valid_resource_unit'
            ),
            models.CheckConstraint(
                check=models.Q(available_quantity__gte=0) & models.Q(available_quantity__lte=models.F('total_quantity')),
                name='available_not_exceed_total'
            )
        ]

    def __str__(self):
        return f"{self.name} ({self.category})"


class ResourceInventoryTransaction(models.Model):
    """Audit log for every inventory change."""
    TRANSACTION_TYPES = [
        ('add', 'Addition'),
        ('remove', 'Removal'),
        ('adjust', 'Manual Adjustment'),
        ('fulfillment', 'Request Fulfillment'),
        ('donation', 'Donation Intake'),
    ]

    id = models.AutoField(primary_key=True)
    resource = models.ForeignKey(Resource, on_delete=models.CASCADE, related_name='inventory_transactions')
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    quantity_delta = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(-9999999999.99)])
    reason = models.TextField(blank=True)
    related_request = models.ForeignKey('relief.ResourceRequest', on_delete=models.SET_NULL, null=True, blank=True)
    related_donation_item = models.ForeignKey('operations.DonationItem', on_delete=models.SET_NULL, null=True, blank=True, related_name='inventory_transactions')
    created_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'resource_inventory_transactions'
        indexes = [
            models.Index(fields=['resource', 'transaction_type']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.resource.name}: {self.transaction_type} ({self.quantity_delta})"

class ResourceRequest(models.Model):
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('fulfilled', 'Fulfilled'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.AutoField(primary_key=True)
    camp = models.ForeignKey('shelters.Camp', on_delete=models.CASCADE)  # String reference
    resource = models.ForeignKey(Resource, on_delete=models.CASCADE)
    quantity_requested = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0.01)])
    quantity_fulfilled = models.DecimalField(max_digits=10, decimal_places=2, default=0, validators=[MinValueValidator(0)])
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    requested_by = models.ForeignKey('users.User', on_delete=models.CASCADE,  # String reference
                                     limit_choices_to={'role__in': ['camp_admin', 'super_admin', 'victim']},
                                     help_text="Can be camp admin, super admin, or victim")
    request_date = models.DateTimeField(auto_now_add=True)
    needed_by = models.DateTimeField()
    reason = models.TextField()

    class Meta:
        db_table = 'resource_requests'
        indexes = [
            models.Index(fields=['camp', 'status']),
            models.Index(fields=['priority', 'needed_by']),
            models.Index(fields=['status', 'request_date']),
        ]
        constraints = [
            models.CheckConstraint(
                check=models.Q(priority__in=['low', 'medium', 'high', 'urgent']),
                name='valid_priority_level'
            ),
            models.CheckConstraint(
                check=models.Q(status__in=['pending', 'approved', 'rejected', 'fulfilled', 'cancelled']),
                name='valid_request_status'
            ),
            models.CheckConstraint(
                check=models.Q(quantity_fulfilled__lte=models.F('quantity_requested')),
                name='fulfillment_not_exceed_request'
            ),
            models.CheckConstraint(
                check=models.Q(needed_by__gt=models.F('request_date')),
                name='needed_by_after_request_date'
            )
        ]

    def __str__(self):
        return f"{self.resource.name} request for {self.camp.name}"

    def save(self, *args, **kwargs):
        previous_status = None
        if self.pk:
            previous_status = ResourceRequest.objects.filter(pk=self.pk).values_list('status', flat=True).first()
        super().save(*args, **kwargs)
        if previous_status and previous_status != self.status:
            ResourceRequestStatusHistory.objects.create(
                request=self,
                previous_status=previous_status,
                new_status=self.status
            )


class ResourceRequestStatusHistory(models.Model):
    """Keeps a full audit trail for resource request status transitions."""
    id = models.AutoField(primary_key=True)
    request = models.ForeignKey(ResourceRequest, on_delete=models.CASCADE, related_name='status_history')
    previous_status = models.CharField(max_length=20, choices=ResourceRequest.STATUS_CHOICES)
    new_status = models.CharField(max_length=20, choices=ResourceRequest.STATUS_CHOICES)
    changed_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True)
    note = models.TextField(blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'resource_request_status_history'
        indexes = [
            models.Index(fields=['request']),
            models.Index(fields=['new_status', 'changed_at']),
        ]

    def __str__(self):
        return f"{self.request_id}: {self.previous_status} → {self.new_status}"