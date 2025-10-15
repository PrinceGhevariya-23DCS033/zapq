import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/offer_model.dart';
import '../../../shared/services/photo_upload_service.dart';
import '../../../core/theme/app_colors.dart';

class OfferManagementWidget extends StatefulWidget {
  final List<OfferModel> offers;
  final String businessId;
  final Function(OfferModel) onOfferCreated;
  final Function(OfferModel) onOfferUpdated;
  final Function(String) onOfferDeleted;

  const OfferManagementWidget({
    Key? key,
    required this.offers,
    required this.businessId,
    required this.onOfferCreated,
    required this.onOfferUpdated,
    required this.onOfferDeleted,
  }) : super(key: key);

  @override
  State<OfferManagementWidget> createState() => _OfferManagementWidgetState();
}

class _OfferManagementWidgetState extends State<OfferManagementWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Offers & Promotions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateOfferDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (widget.offers.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No offers created yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create attractive offers to bring in more customers',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateOfferDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Offer'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.offers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = widget.offers[index];
              return OfferCard(
                offer: offer,
                onEdit: () => _showEditOfferDialog(offer),
                onDelete: () => _deleteOffer(offer.id),
                onToggleStatus: () => _toggleOfferStatus(offer),
              );
            },
          ),
      ],
    );
  }

  void _showCreateOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateEditOfferDialog(
        businessId: widget.businessId,
        onOfferSaved: widget.onOfferCreated,
      ),
    );
  }

  void _showEditOfferDialog(OfferModel offer) {
    showDialog(
      context: context,
      builder: (context) => CreateEditOfferDialog(
        businessId: widget.businessId,
        offer: offer,
        onOfferSaved: widget.onOfferUpdated,
      ),
    );
  }

  void _deleteOffer(String offerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text('Are you sure you want to delete this offer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onOfferDeleted(offerId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleOfferStatus(OfferModel offer) {
    final updatedOffer = offer.copyWith(isActive: !offer.isActive);
    widget.onOfferUpdated(updatedOffer);
  }
}

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const OfferCard({
    Key? key,
    required this.offer,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: offer.isActive ? AppColors.primary.withOpacity(0.3) : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster image
          if (offer.posterUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                offer.posterUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: offer.isActive ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        offer.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  offer.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Discount info
                if (offer.discountPercentage != null || 
                    (offer.originalPrice != null && offer.discountedPrice != null))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        if (offer.discountPercentage != null)
                          Text(
                            '${offer.discountPercentage!.toInt()}% OFF',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        else if (offer.originalPrice != null && offer.discountedPrice != null)
                          RichText(
                            text: TextSpan(
                              style: TextStyle(color: AppColors.primary),
                              children: [
                                TextSpan(
                                  text: '\$${offer.discountedPrice!.toStringAsFixed(2)} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: '\$${offer.originalPrice!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Date range
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(offer.startDate)} - ${_formatDate(offer.endDate)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          offer.isActive ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(offer.isActive ? 'Pause' : 'Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: offer.isActive ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Create/Edit Offer Dialog
class CreateEditOfferDialog extends StatefulWidget {
  final String businessId;
  final OfferModel? offer;
  final Function(OfferModel) onOfferSaved;

  const CreateEditOfferDialog({
    Key? key,
    required this.businessId,
    this.offer,
    required this.onOfferSaved,
  }) : super(key: key);

  @override
  State<CreateEditOfferDialog> createState() => _CreateEditOfferDialogState();
}

class _CreateEditOfferDialogState extends State<CreateEditOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  
  final PhotoUploadService _photoService = PhotoUploadService();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _posterUrl;
  File? _posterFile;
  bool _isUploading = false;
  List<String> _terms = [];
  final _termController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.offer != null) {
      _populateFields(widget.offer!);
    }
  }

  void _populateFields(OfferModel offer) {
    _titleController.text = offer.title;
    _descriptionController.text = offer.description;
    _discountController.text = offer.discountPercentage?.toString() ?? '';
    _originalPriceController.text = offer.originalPrice?.toString() ?? '';
    _discountedPriceController.text = offer.discountedPrice?.toString() ?? '';
    _startDate = offer.startDate;
    _endDate = offer.endDate;
    _posterUrl = offer.posterUrl;
    _terms = List.from(offer.terms);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.offer == null ? 'Create New Offer' : 'Edit Offer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster upload
                      _buildPosterSection(),
                      const SizedBox(height: 16),
                      
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Offer Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter offer title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Discount section
                      _buildDiscountSection(),
                      const SizedBox(height: 16),
                      
                      // Date range
                      _buildDateSection(),
                      const SizedBox(height: 16),
                      
                      // Terms
                      _buildTermsSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.offer == null ? 'Create' : 'Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Offer Poster', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPosterImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _posterFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_posterFile!, fit: BoxFit.cover),
                  )
                : _posterUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_posterUrl!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to add poster image'),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Discount Details', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Discount %',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('OR'),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Original Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _discountedPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sale Price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Offer Period', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Start Date'),
                subtitle: Text(_formatDate(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('End Date'),
                subtitle: Text(_formatDate(_endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _termController,
                decoration: const InputDecoration(
                  hintText: 'Add a term or condition',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTerm,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _terms.map((term) => Chip(
            label: Text(term),
            onDeleted: () => _removeTerm(term),
          )).toList(),
        ),
      ],
    );
  }

  Future<void> _pickPosterImage() async {
    final ImageSource? source = await _photoService.showImageSourceDialog(context);
    if (source == null) return;

    final XFile? image = await _photoService.pickImage(source: source);
    if (image != null) {
      setState(() {
        _posterFile = File(image.path);
      });
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addTerm() {
    if (_termController.text.trim().isNotEmpty) {
      setState(() {
        _terms.add(_termController.text.trim());
        _termController.clear();
      });
    }
  }

  void _removeTerm(String term) {
    setState(() {
      _terms.remove(term);
    });
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? posterUrl = _posterUrl;
      
      // Upload poster if new file selected
      if (_posterFile != null) {
        final offerId = widget.offer?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        posterUrl = await _photoService.uploadOfferPoster(
          imageFile: _posterFile!,
          businessId: widget.businessId,
          offerId: offerId,
        );
      }

      final offer = OfferModel(
        id: widget.offer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        businessId: widget.businessId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        posterUrl: posterUrl,
        discountPercentage: _discountController.text.isNotEmpty 
            ? double.tryParse(_discountController.text) 
            : null,
        originalPrice: _originalPriceController.text.isNotEmpty 
            ? double.tryParse(_originalPriceController.text) 
            : null,
        discountedPrice: _discountedPriceController.text.isNotEmpty 
            ? double.tryParse(_discountedPriceController.text) 
            : null,
        startDate: _startDate,
        endDate: _endDate,
        isActive: widget.offer?.isActive ?? true,
        createdAt: widget.offer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        terms: _terms,
        category: widget.offer?.category,
      );

      widget.onOfferSaved(offer);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _termController.dispose();
    super.dispose();
  }
}