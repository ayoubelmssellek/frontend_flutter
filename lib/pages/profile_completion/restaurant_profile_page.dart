// import 'package:flutter/material.dart';
// import 'package:flutter/animation.dart';
// import 'package:image_picker/image_picker.dart';
// import '../home/restaurant_home_page.dart';

// class RestaurantProfilePage extends StatefulWidget {
//   const RestaurantProfilePage({super.key});

//   @override
//   State<RestaurantProfilePage> createState() => _RestaurantProfilePageState();
// }

// class _RestaurantProfilePageState extends State<RestaurantProfilePage> with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _cuisineController = TextEditingController();
//   final _deliveryTimeController = TextEditingController();
//   final _minOrderController = TextEditingController();
  
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
  
//   List<String> _selectedCuisines = [];
//   List<XFile> _restaurantImages = [];
//   XFile? _logoImage;
  
//   bool _isLoading = false;
//   int _currentStep = 0;
//   final List<String> _cuisineOptions = [
//     'Italian', 'Chinese', 'Indian', 'Mexican', 'Japanese',
//     'Thai', 'American', 'Mediterranean', 'French', 'Vietnamese'
//   ];

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
    
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
    
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));
    
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _cuisineController.dispose();
//     _deliveryTimeController.dispose();
//     _minOrderController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImage(bool isLogo) async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
//     if (image != null) {
//       setState(() {
//         if (isLogo) {
//           _logoImage = image;
//         } else {
//           _restaurantImages.add(image);
//         }
//       });
//     }
//   }

//   void _toggleCuisine(String cuisine) {
//     setState(() {
//       if (_selectedCuisines.contains(cuisine)) {
//         _selectedCuisines.remove(cuisine);
//       } else {
//         _selectedCuisines.add(cuisine);
//       }
//     });
//   }

//   Future<void> _completeProfile() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
      
//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));
      
//       setState(() => _isLoading = false);
      
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const RestaurantHomePage()),
//       );
//     }
//   }

//   Widget _buildStepIndicator() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: List.generate(3, (index) {
//           return Expanded(
//             child: Column(
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: index <= _currentStep 
//                         ? Colors.deepOrange 
//                         : Colors.grey.shade300,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Center(
//                     child: Text(
//                       '${index + 1}',
//                       style: TextStyle(
//                         color: index <= _currentStep ? Colors.white : Colors.grey.shade600,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   ['Basic Info', 'Details', 'Complete'][index],
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: index <= _currentStep ? Colors.deepOrange : Colors.grey.shade500,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildBasicInfoStep() {
//     return SlideTransition(
//       position: _slideAnimation,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Logo Upload
//             Center(
//               child: Column(
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.grey.shade300),
//                         ),
//                         child: _logoImage != null
//                             ? CircleAvatar(
//                                 backgroundImage: NetworkImage(_logoImage!.path),
//                                 radius: 60,
//                               )
//                             : const Icon(
//                                 Icons.restaurant,
//                                 size: 40,
//                                 color: Colors.grey,
//                               ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             color: Colors.deepOrange,
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 2),
//                           ),
//                           child: IconButton(
//                             icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
//                             onPressed: () => _pickImage(true),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "Upload Logo",
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             const SizedBox(height: 32),
            
//             // Restaurant Name
//             TextFormField(
//               controller: _nameController,
//               decoration: InputDecoration(
//                 labelText: 'Restaurant Name',
//                 prefixIcon: Icon(Icons.restaurant, color: Colors.grey.shade500),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Colors.deepOrange),
//                 ),
//               ),
//               validator: (val) => val!.isEmpty ? 'Restaurant name is required' : null,
//             ),
            
//             const SizedBox(height: 20),
            
//             // Description
//             TextFormField(
//               controller: _descriptionController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 labelText: 'Description',
//                 alignLabelWithHint: true,
//                 prefixIcon: Icon(Icons.description, color: Colors.grey.shade500),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Colors.deepOrange),
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 20),
            
//             // Cuisine Types
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Cuisine Types",
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontWeight: FontWeight.w500,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: _cuisineOptions.map((cuisine) {
//                     final isSelected = _selectedCuisines.contains(cuisine);
//                     return FilterChip(
//                       label: Text(cuisine),
//                       selected: isSelected,
//                       onSelected: (_) => _toggleCuisine(cuisine),
//                       selectedColor: Colors.deepOrange.withOpacity(0.2),
//                       checkmarkColor: Colors.deepOrange,
//                       labelStyle: TextStyle(
//                         color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailsStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Contact Information
//         Text(
//           "Contact Information",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 20),
        
//         TextFormField(
//           controller: _phoneController,
//           keyboardType: TextInputType.phone,
//           decoration: InputDecoration(
//             labelText: 'Phone Number',
//             prefixIcon: Icon(Icons.phone, color: Colors.grey.shade500),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.deepOrange),
//             ),
//           ),
//         ),
        
//         const SizedBox(height: 20),
        
//         TextFormField(
//           controller: _emailController,
//           keyboardType: TextInputType.emailAddress,
//           decoration: InputDecoration(
//             labelText: 'Email Address',
//             prefixIcon: Icon(Icons.email, color: Colors.grey.shade500),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.deepOrange),
//             ),
//           ),
//         ),
        
//         const SizedBox(height: 20),
        
//         TextFormField(
//           controller: _addressController,
//           maxLines: 2,
//           decoration: InputDecoration(
//             labelText: 'Address',
//             prefixIcon: Icon(Icons.location_on, color: Colors.grey.shade500),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.deepOrange),
//             ),
//           ),
//         ),
        
//         const SizedBox(height: 32),
        
//         // Restaurant Images
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Restaurant Images",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               "Add photos of your restaurant, food, and ambiance",
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 16),
//             Wrap(
//               spacing: 12,
//               runSpacing: 12,
//               children: [
//                 ..._restaurantImages.map((image) => Stack(
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         image: DecorationImage(
//                           image: NetworkImage(image.path),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: -8,
//                       right: -8,
//                       child: IconButton(
//                         icon: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.close, size: 16, color: Colors.white),
//                         ),
//                         onPressed: () => setState(() => _restaurantImages.remove(image)),
//                       ),
//                     ),
//                   ],
//                 )),
//                 GestureDetector(
//                   onTap: () => _pickImage(false),
//                   child: Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
//                     ),
//                     child: const Icon(Icons.add, size: 32, color: Colors.grey),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildBusinessSettingsStep() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Business Settings",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 20),
        
//         TextFormField(
//           controller: _deliveryTimeController,
//           decoration: InputDecoration(
//             labelText: 'Average Delivery Time (minutes)',
//             prefixIcon: Icon(Icons.timer, color: Colors.grey.shade500),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.deepOrange),
//             ),
//           ),
//           keyboardType: TextInputType.number,
//         ),
        
//         const SizedBox(height: 20),
        
//         TextFormField(
//           controller: _minOrderController,
//           decoration: InputDecoration(
//             labelText: 'Minimum Order Amount',
//             prefixIcon: Icon(Icons.attach_money, color: Colors.grey.shade500),
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.deepOrange),
//             ),
//           ),
//           keyboardType: TextInputType.number,
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           "Complete Profile",
//           style: TextStyle(
//             color: Colors.grey.shade800,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       body: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             _buildStepIndicator(),
//             const Divider(height: 1),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       if (_currentStep == 0) _buildBasicInfoStep(),
//                       if (_currentStep == 1) _buildDetailsStep(),
//                       if (_currentStep == 2) _buildBusinessSettingsStep(),
                      
//                       const SizedBox(height: 40),
                      
//                       // Navigation Buttons
//                       Row(
//                         children: [
//                           if (_currentStep > 0)
//                             Expanded(
//                               child: OutlinedButton(
//                                 style: OutlinedButton.styleFrom(
//                                   padding: const EdgeInsets.symmetric(vertical: 16),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   side: BorderSide(color: Colors.grey.shade300),
//                                 ),
//                                 onPressed: () => setState(() => _currentStep--),
//                                 child: Text(
//                                   "Back",
//                                   style: TextStyle(
//                                     color: Colors.grey.shade700,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           if (_currentStep > 0) const SizedBox(width: 16),
//                           Expanded(
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.deepOrange,
//                                 foregroundColor: Colors.white,
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               onPressed: () {
//                                 if (_currentStep < 2) {
//                                   setState(() => _currentStep++);
//                                 } else {
//                                   _completeProfile();
//                                 }
//                               },
//                               child: _isLoading
//                                   ? const SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                         valueColor: AlwaysStoppedAnimation(Colors.white),
//                                       ),
//                                     )
//                                   : Text(
//                                       _currentStep == 2 ? "Complete Setup" : "Continue",
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }