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
            )
        ]

    def __str__(self):
        return f"{self.name} ({self.category})"

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
                                     limit_choices_to={'role__in': ['camp_admin', 'super_admin']})
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