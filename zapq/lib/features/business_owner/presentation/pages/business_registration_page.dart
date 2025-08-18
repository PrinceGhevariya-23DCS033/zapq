import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/enhanced_business_provider.dart';
import '../../../../shared/models/business_model.dart';

class BusinessRegistrationPage extends StatefulWidget {
  const BusinessRegistrationPage({super.key});

  @override
  State<BusinessRegistrationPage> createState() => _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState extends State<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedCategory = 'salon';
  final List<String> _categories = [
    'salon',
    'beauty_parlor',
    'barbershop',
    'spa',
    'medical',
    'dental',
    'restaurant',
    'retail',
    'fitness',
    'auto',
    'education',
    'other'
  ];

  final List<ServiceModel> _services = [];
  BusinessHours _businessHours = BusinessHours.defaultHours();

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'salon':
        return 'Hair Salon';
      case 'beauty_parlor':
        return 'Beauty Parlor';
      case 'barbershop':
        return 'Barbershop';
      case 'spa':
        return 'Spa & Wellness';
      case 'medical':
        return 'Medical Clinic';
      case 'dental':
        return 'Dental Clinic';
      case 'restaurant':
        return 'Restaurant';
      case 'retail':
        return 'Retail Shop';
      case 'fitness':
        return 'Fitness Center';
      case 'auto':
        return 'Auto Service';
      case 'education':
        return 'Education';
      default:
        return 'Other';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _registerBusiness() async {
    if (_formKey.currentState!.validate()) {
      if (_services.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one service')),
        );
        return;
      }

      final businessProvider = context.read<BusinessProvider>();
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Registering your business...'),
            ],
          ),
        ),
      );

      final business = BusinessModel(
        id: '',
        ownerId: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        imageUrls: [],
        operatingHours: {},
        maxCustomersPerDay: 50,
        averageServiceTimeMinutes: 30,
        isActive: true,
        rating: 0.0,
        totalRatings: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        services: _services,
        businessHours: _businessHours,
      );

      final success = await businessProvider.registerBusiness(business);
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (success && mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 8),
                Text('Success!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_nameController.text} has been registered successfully!'),
                const SizedBox(height: 8),
                const Text('You can now start accepting bookings from customers.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close success dialog
                  // Navigate to business dashboard and refresh it
                  context.go('/business-home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Registration Failed'),
              ],
            ),
            content: Text(businessProvider.errorMessage ?? 'An unexpected error occurred. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _addService() {
    showDialog(
      context: context,
      builder: (context) => _ServiceDialog(
        onServiceAdded: (service) {
          setState(() {
            _services.add(service);
          });
        },
      ),
    );
  }

  void _editService(int index) {
    showDialog(
      context: context,
      builder: (context) => _ServiceDialog(
        service: _services[index],
        onServiceAdded: (service) {
          setState(() {
            _services[index] = service;
          });
        },
      ),
    );
  }

  void _deleteService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  void _editBusinessHours() {
    showDialog(
      context: context,
      builder: (context) => _BusinessHoursDialog(
        businessHours: _businessHours,
        onHoursUpdated: (hours) {
          setState(() {
            _businessHours = hours;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Register Your Business'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryDisplayName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Services Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Services',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addService,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Service'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_services.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_business,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No services added yet',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(service.name),
                                subtitle: Text('₹${service.price.toStringAsFixed(0)} • ${service.durationMinutes} min'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editService(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteService(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Business Hours Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Business Hours',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _editBusinessHours,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Edit Hours'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Display current hours
                      ...['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
                          .map((day) {
                        final dayHours = _businessHours.hours[day];
                        final dayName = day[0].toUpperCase() + day.substring(1);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  dayName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                dayHours?.isOpen ?? false
                                    ? '${dayHours!.openTime} - ${dayHours.closeTime}'
                                    : 'Closed',
                                style: TextStyle(
                                  color: dayHours?.isOpen ?? false
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                child: Consumer<BusinessProvider>(
                  builder: (context, businessProvider, child) {
                    return ElevatedButton(
                      onPressed: businessProvider.isLoading ? null : _registerBusiness,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: businessProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Register Business',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final ServiceModel? service;
  final Function(ServiceModel) onServiceAdded;

  const _ServiceDialog({
    this.service,
    required this.onServiceAdded,
  });

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _capacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _descriptionController.text = widget.service!.description;
      _priceController.text = widget.service!.price.toString();
      _durationController.text = widget.service!.durationMinutes.toString();
      _capacityController.text = widget.service!.maxCapacity.toString();
    } else {
      _capacityController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Max Capacity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _priceController.text.isNotEmpty) {
              final service = ServiceModel(
                id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                description: _descriptionController.text,
                price: double.tryParse(_priceController.text) ?? 0,
                durationMinutes: int.tryParse(_durationController.text) ?? 30,
                maxCapacity: int.tryParse(_capacityController.text) ?? 1,
              );
              widget.onServiceAdded(service);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _BusinessHoursDialog extends StatefulWidget {
  final BusinessHours businessHours;
  final Function(BusinessHours) onHoursUpdated;

  const _BusinessHoursDialog({
    required this.businessHours,
    required this.onHoursUpdated,
  });

  @override
  State<_BusinessHoursDialog> createState() => _BusinessHoursDialogState();
}

class _BusinessHoursDialogState extends State<_BusinessHoursDialog> {
  late Map<String, DayHours> _hours;

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.businessHours.hours);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Business Hours'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
                .map((day) => _buildDayHours(day))
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onHoursUpdated(BusinessHours(hours: _hours));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDayHours(String day) {
    final dayHours = _hours[day]!;
    final dayName = day[0].toUpperCase() + day.substring(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: dayHours.isOpen,
                  onChanged: (value) {
                    setState(() {
                      _hours[day] = DayHours(
                        isOpen: value,
                        openTime: dayHours.openTime,
                        closeTime: dayHours.closeTime,
                      );
                    });
                  },
                ),
              ],
            ),
            if (dayHours.isOpen) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(day, true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Open: ${dayHours.openTime}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(day, false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Close: ${dayHours.closeTime}'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final dayHours = _hours[day]!;
    final currentTime = isOpenTime ? dayHours.openTime : dayHours.closeTime;
    final timeParts = currentTime.split(':');
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );

    if (time != null) {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        _hours[day] = DayHours(
          isOpen: dayHours.isOpen,
          openTime: isOpenTime ? timeString : dayHours.openTime,
          closeTime: isOpenTime ? dayHours.closeTime : timeString,
        );
      });
    }
  }
}
