import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class OffersNegotiationsPage extends StatefulWidget {
  const OffersNegotiationsPage({super.key});

  @override
  State<OffersNegotiationsPage> createState() => _OffersNegotiationsPageState();
}

class _OffersNegotiationsPageState extends State<OffersNegotiationsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> offers = [];

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    final response = await supabase
        .from('offers')
        .select('*')
        .order('date_time', ascending: false);
    setState(() {
      offers = response;
    });
  }

  List<dynamic> get activeOffers =>
      offers.where((o) => o['status'] == 'pending').toList();

  List<dynamic> get previousOffers =>
      offers.where((o) => o['status'] != 'pending').toList();

  Widget buildOfferCard(dynamic offer) {
    final price = NumberFormat.simpleCurrency().format(offer['offer_price']);
    final received = timeago.format(DateTime.parse(offer['date_time']));
    final status = offer['status'];

    Color statusColor = Colors.grey;
    if (status == 'pending') statusColor = Colors.blue;
    if (status == 'accepted') statusColor = Colors.green;
    if (status == 'declined') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company info row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  radius: 24,
                  child: const Icon(Icons.storefront, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    offer['message'] ?? 'Product title',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text("Received $received", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => updateStatus(offer['offer_id'], 'accepted'),
                      child: const Text("Accept"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () {
                        // Add your counter logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Counter offer clicked")));
                      },
                      child: const Text("Counter"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                      onPressed: () => updateStatus(offer['offer_id'], 'declined'),
                      child: const Text("Decline"),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await supabase.from('offers').update({'status': newStatus}).eq('offer_id', id);
    fetchOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offers & Negotiations"),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list))
        ],
      ),
      body: ListView(
        children: [
          if (activeOffers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Active Offers (${activeOffers.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ...activeOffers.map(buildOfferCard),
          if (previousOffers.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Previous Offers", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ...previousOffers.map(buildOfferCard),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              onPressed: () {}, // Add new counter offer logic
              child: const Text("New Counter Offer"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}