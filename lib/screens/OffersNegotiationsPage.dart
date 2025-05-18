import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OffersNegotiationsPage extends StatefulWidget {
  final String userId;

  const OffersNegotiationsPage({
    super.key,
    required this.userId,
  });

  @override
  State<OffersNegotiationsPage> createState() => _OffersNegotiationsPageState();
}

class _OffersNegotiationsPageState extends State<OffersNegotiationsPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> activeOffers = [];
  List<Map<String, dynamic>> previousOffers = [];

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      // Fetch active offers (pending status)
      final activeResponse = await Supabase.instance.client
          .from('product_offers')
          .select('*, products(*), users(*)')
          .eq('user_id', widget.userId)
          .eq('status', 'pending')
          .order('date_time', ascending: false);
      
      // Fetch previous offers (accepted or declined)
      final previousResponse = await Supabase.instance.client
          .from('product_offers')
          .select('*, products(*), users(*)')
          .eq('user_id', widget.userId)
          .in_('status', ['accepted', 'declined'])
          .order('date_time', ascending: false);

      setState(() {
        activeOffers = List<Map<String, dynamic>>.from(activeResponse);
        previousOffers = List<Map<String, dynamic>>.from(previousResponse);
        isLoading = false;
      });
    } catch (e) {
      print('Failed to fetch offers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('product_offers')
          .update({'status': newStatus})
          .eq('offer_id', offerId);
      
      // Refresh offers list
      fetchOffers();
    } catch (e) {
      print('Failed to update offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to $newStatus offer. Please try again.')),
      );
    }
  }

  String formatTimeAgo(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Offers & Negotiations',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active Offers Section
                Text(
                  'Active Offers (${activeOffers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...activeOffers.map((offer) => _buildOfferCard(
                      offer,
                      isActive: true,
                    )),
                const SizedBox(height: 24),
                
                // Previous Offers Section
                const Text(
                  'Previous Offers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...previousOffers.map((offer) => _buildOfferCard(
                      offer,
                      isActive: false,
                    )),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              _showNewCounterOfferDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              'New Counter Offer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, {required bool isActive}) {
    final statusColor = offer['status'] == 'pending'
        ? Colors.blue
        : offer['status'] == 'accepted'
            ? Colors.green
            : Colors.red;
    
    final statusText = offer['status'] == 'pending'
        ? 'Pending'
        : offer['status'] == 'accepted'
            ? 'Accepted'
            : 'Declined';

    final companyName = offer['products']['company'] ?? 'Company';
    final positionTitle = offer['products']['position'] ?? 'Position';
    final offerAmount = NumberFormat.currency(symbol: '\$').format(offer['offer_amount'] ?? 0);
    final timeAgo = formatTimeAgo(offer['date_time']);
    final companyLogo = offer['products']['company_logo'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company info row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: companyLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            companyLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.business),
                          ),
                        )
                      : const Icon(Icons.business),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        positionTitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Offer amount
            Text(
              offerAmount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Time received
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Received $timeAgo' : timeAgo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Action buttons for active offers
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOfferStatus(offer['offer_id'], 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCounterOfferDialog(context, offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Counter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => updateOfferStatus(offer['offer_id'], 'declined'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline'),
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

  void _showCounterOfferDialog(BuildContext context, Map<String, dynamic> offer) {
    final TextEditingController counterOfferController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Make Counter Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current offer: ${NumberFormat.currency(symbol: '\$').format(offer['offer_amount'] ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: counterOfferController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your Counter Offer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (counterOfferController.text.isNotEmpty) {
                  final amount = double.tryParse(counterOfferController.text.replaceAll(',', ''));
                  
                  if (amount != null) {
                    Navigator.of(context).pop();
                    
                    try {
                      // Create new counter offer
                      await Supabase.instance.client.from('product_offers').insert({
                        'product_id': offer['product_id'],
                        'offer_amount': amount,
                        'status': 'pending',
                        'date_time': DateTime.now().toIso8601String(),
                        'user_id': widget.userId,
                        'is_counter': true,
                        'reference_offer_id': offer['offer_id'],
                      });
                      
                      // Update original offer
                      await updateOfferStatus(offer['offer_id'], 'countered');
                      
                      // Refresh offers
                      fetchOffers();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Counter offer sent successfully')),
                      );
                    } catch (e) {
                      print('Failed to create counter offer: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send counter offer')),
                      );
                    }
                  }
                }
              },
              child: const Text('Send Counter Offer'),
            ),
          ],
        );
      },
    );
  }

  void _showNewCounterOfferDialog(BuildContext context) {
    final TextEditingController productIdController = TextEditingController();
    final TextEditingController offerAmountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Counter Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productIdController,
                decoration: const InputDecoration(
                  labelText: 'Product ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: offerAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Offer Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (productIdController.text.isNotEmpty && 
                    offerAmountController.text.isNotEmpty) {
                  final amount = double.tryParse(offerAmountController.text.replaceAll(',', ''));
                  
                  if (amount != null) {
                    Navigator.of(context).pop();
                    
                    try {
                      // Create new offer
                      await Supabase.instance.client.from('product_offers').insert({
                        'product_id': productIdController.text,
                        'offer_amount': amount,
                        'status': 'pending',
                        'date_time': DateTime.now().toIso8601String(),
                        'user_id': widget.userId,
                        'is_counter': false,
                      });
                      
                      // Refresh offers
                      fetchOffers();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New offer sent successfully')),
                      );
                    } catch (e) {
                      print('Failed to create offer: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send offer')),
                      );
                    }
                  }
                }
              },
              child: const Text('Send Offer'),
            ),
          ],
        );
      },
    );
  }
}