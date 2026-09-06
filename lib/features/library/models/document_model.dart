import 'package:flutter/foundation.dart';

enum DocumentStatus { active, expired, archived }

extension DocumentStatusExtension on DocumentStatus {
  String get displayName {
    switch (this) {
      case DocumentStatus.active:
        return 'Active';
      case DocumentStatus.expired:
        return 'Expired';
      case DocumentStatus.archived:
        return 'Archived';
    }
  }

  static DocumentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'active':
        return DocumentStatus.active;
      case 'expired':
        return DocumentStatus.expired;
      case 'archived':
      case 'sold properties documents':
        return DocumentStatus.archived;
      default:
        return DocumentStatus.active;
    }
  }
}

class RentalDocument {
  final String id;
  final String name;
  final String propertyName;
  final String tenantName;
  final String ownerName;
  final String documentType;
  final DateTime uploadDate;
  final String uploadedBy;
  final DocumentStatus status;
  final String description;
  final String fileSize;
  final String fileExtension;

  RentalDocument({
    required this.id,
    required this.name,
    required this.propertyName,
    required this.tenantName,
    required this.ownerName,
    required this.documentType,
    required this.uploadDate,
    required this.uploadedBy,
    required this.status,
    required this.description,
    required this.fileSize,
    required this.fileExtension,
  });

  RentalDocument copyWith({
    String? id,
    String? name,
    String? propertyName,
    String? tenantName,
    String? ownerName,
    String? documentType,
    DateTime? uploadDate,
    String? uploadedBy,
    DocumentStatus? status,
    String? description,
    String? fileSize,
    String? fileExtension,
  }) {
    return RentalDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      propertyName: propertyName ?? this.propertyName,
      tenantName: tenantName ?? this.tenantName,
      ownerName: ownerName ?? this.ownerName,
      documentType: documentType ?? this.documentType,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      status: status ?? this.status,
      description: description ?? this.description,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
    );
  }

  static List<RentalDocument> getMockData() {
    return [
      RentalDocument(
        id: 'rent-1',
        name: 'Rental Agreement - Villa 4B',
        propertyName: 'Greenwood Villa B4',
        tenantName: 'Rajesh Kumar',
        ownerName: 'Amit Patel',
        documentType: 'Rental Agreement',
        uploadDate: DateTime.now().subtract(const Duration(days: 12)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Signed rental lease agreement for Greenwood Villa B4 (2026-2027 term).',
        fileSize: '2.4 MB',
        fileExtension: 'pdf',
      ),
      RentalDocument(
        id: 'rent-2',
        name: 'Tenant Passport & Visa Proof',
        propertyName: 'Skyline Apartments 102',
        tenantName: 'Sneha Reddy',
        ownerName: 'Vijay Mallya',
        documentType: 'Tenant ID Proof',
        uploadDate: DateTime.now().subtract(const Duration(days: 30)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Scanned copy of international passport and resident visa details.',
        fileSize: '1.8 MB',
        fileExtension: 'jpg',
      ),
      RentalDocument(
        id: 'rent-3',
        name: 'Security Deposit Receipt',
        propertyName: 'Orchid Residency 502',
        tenantName: 'Aravind Swamy',
        ownerName: 'Karan Johar',
        documentType: 'Security Deposit Receipt',
        uploadDate: DateTime.now().subtract(const Duration(days: 45)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Payment receipt for Security Deposit of ₹1,50,000.',
        fileSize: '350 KB',
        fileExtension: 'pdf',
      ),
      RentalDocument(
        id: 'rent-4',
        name: 'Electricity Bill - Jun 2026',
        propertyName: 'Greenwood Villa B4',
        tenantName: 'Rajesh Kumar',
        ownerName: 'Amit Patel',
        documentType: 'Electricity Bill',
        uploadDate: DateTime.now().subtract(const Duration(days: 5)),
        uploadedBy: 'admin',
        status: DocumentStatus.expired,
        description: 'Paid utility statement for Electricity (June cycle). Billing expired.',
        fileSize: '1.1 MB',
        fileExtension: 'pdf',
      ),
      RentalDocument(
        id: 'rent-5',
        name: 'Property Entrance Video walkthrough',
        propertyName: 'Prestige Towers 3C',
        tenantName: 'John Doe',
        ownerName: 'Suresh Raina',
        documentType: 'Property Videos',
        uploadDate: DateTime.now().subtract(const Duration(hours: 4)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Video inspection of property check-in status.',
        fileSize: '14.5 MB',
        fileExtension: 'mp4',
      ),
      RentalDocument(
        id: 'rent-6',
        name: 'Water Bill - May 2026',
        propertyName: 'Prestige Towers 3C',
        tenantName: 'John Doe',
        ownerName: 'Suresh Raina',
        documentType: 'Water Bill',
        uploadDate: DateTime.now().subtract(const Duration(days: 60)),
        uploadedBy: 'admin',
        status: DocumentStatus.archived,
        description: 'Archived water board utility bill.',
        fileSize: '890 KB',
        fileExtension: 'pdf',
      ),
    ];
  }
}

class ResaleDocument {
  final String id;
  final String name;
  final String propertyName;
  final String sellerName;
  final String buyerName;
  final String documentType;
  final DateTime uploadDate;
  final String uploadedBy;
  final DocumentStatus status;
  final String description;
  final String fileSize;
  final String fileExtension;

  ResaleDocument({
    required this.id,
    required this.name,
    required this.propertyName,
    required this.sellerName,
    required this.buyerName,
    required this.documentType,
    required this.uploadDate,
    required this.uploadedBy,
    required this.status,
    required this.description,
    required this.fileSize,
    required this.fileExtension,
  });

  ResaleDocument copyWith({
    String? id,
    String? name,
    String? propertyName,
    String? sellerName,
    String? buyerName,
    String? documentType,
    DateTime? uploadDate,
    String? uploadedBy,
    DocumentStatus? status,
    String? description,
    String? fileSize,
    String? fileExtension,
  }) {
    return ResaleDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      propertyName: propertyName ?? this.propertyName,
      sellerName: sellerName ?? this.sellerName,
      buyerName: buyerName ?? this.buyerName,
      documentType: documentType ?? this.documentType,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      status: status ?? this.status,
      description: description ?? this.description,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
    );
  }

  static List<ResaleDocument> getMockData() {
    return [
      ResaleDocument(
        id: 'sale-1',
        name: 'Registered Sale Deed - 3BHK',
        propertyName: 'Palm Meadows Villa 12',
        sellerName: 'Vikram Seth',
        buyerName: 'Aditya Birla',
        documentType: 'Sale Deed',
        uploadDate: DateTime.now().subtract(const Duration(days: 3)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Official registered copy of Sale Deed verified by Sub-registrar.',
        fileSize: '4.8 MB',
        fileExtension: 'pdf',
      ),
      ResaleDocument(
        id: 'sale-2',
        name: 'Sale Agreement Draft',
        propertyName: 'DLF CyberCity Suite A',
        sellerName: 'Rohan Mehra',
        buyerName: 'Kapil Dev',
        documentType: 'Sale Agreement',
        uploadDate: DateTime.now().subtract(const Duration(days: 20)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Initial draft of Sale Agreement with advance payment clause.',
        fileSize: '1.2 MB',
        fileExtension: 'docx',
      ),
      ResaleDocument(
        id: 'sale-3',
        name: 'NOC from Society Board',
        propertyName: 'Palm Meadows Villa 12',
        sellerName: 'Vikram Seth',
        buyerName: 'Aditya Birla',
        documentType: 'NOC',
        uploadDate: DateTime.now().subtract(const Duration(days: 15)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'No Objection Certificate from Palm Meadows Resident Welfare Association.',
        fileSize: '420 KB',
        fileExtension: 'pdf',
      ),
      ResaleDocument(
        id: 'sale-4',
        name: 'Tax Assessment Receipt 2025',
        propertyName: 'DLF CyberCity Suite A',
        sellerName: 'Rohan Mehra',
        buyerName: 'Kapil Dev',
        documentType: 'Tax Receipt',
        uploadDate: DateTime.now().subtract(const Duration(days: 90)),
        uploadedBy: 'admin',
        status: DocumentStatus.expired,
        description: 'Municipal property tax receipt for assessment year 2025.',
        fileSize: '750 KB',
        fileExtension: 'pdf',
      ),
      ResaleDocument(
        id: 'sale-5',
        name: 'Property Structural Blueprint',
        propertyName: 'Silver Oak Mansions',
        sellerName: 'Priya Dutt',
        buyerName: 'Rahul Bajaj',
        documentType: 'Floor Plan',
        uploadDate: DateTime.now().subtract(const Duration(hours: 18)),
        uploadedBy: 'admin',
        status: DocumentStatus.active,
        description: 'Approved structural building plans and floor layouts.',
        fileSize: '8.2 MB',
        fileExtension: 'pdf',
      ),
      ResaleDocument(
        id: 'sale-6',
        name: 'Bank Loan Sanction Letter',
        propertyName: 'Silver Oak Mansions',
        sellerName: 'Priya Dutt',
        buyerName: 'Rahul Bajaj',
        documentType: 'Loan Documents',
        uploadDate: DateTime.now().subtract(const Duration(days: 50)),
        uploadedBy: 'admin',
        status: DocumentStatus.archived,
        description: 'HDFC Home Loan sanction copy for ₹2,40,00,000.',
        fileSize: '2.1 MB',
        fileExtension: 'pdf',
      ),
    ];
  }
}

class ServiceAgentDocument {
  final String id;
  final String agentName;
  final String serviceType;
  final String mobileNumber;
  final String documentName;
  final String documentType;
  final DateTime uploadDate;
  final String uploadedBy;
  final DocumentStatus status;
  final String description;
  final String fileSize;
  final String fileExtension;
  final String? fileUrl;

  // New fields
  final String approvalStatus; // 'pending', 'approved', 'rejected', 'active'
  final String? agentImageUrl;
  final String? dateOfBirth;
  final List<String> area;

  ServiceAgentDocument({
    required this.id,
    required this.agentName,
    required this.serviceType,
    required this.mobileNumber,
    required this.documentName,
    required this.documentType,
    required this.uploadDate,
    required this.uploadedBy,
    required this.status,
    required this.description,
    required this.fileSize,
    required this.fileExtension,
    this.fileUrl,
    this.approvalStatus = 'approved',
    this.agentImageUrl,
    this.dateOfBirth,
    this.area = const [],
  });

  ServiceAgentDocument copyWith({
    String? id,
    String? agentName,
    String? serviceType,
    String? mobileNumber,
    String? documentName,
    String? documentType,
    DateTime? uploadDate,
    String? uploadedBy,
    DocumentStatus? status,
    String? description,
    String? fileSize,
    String? fileExtension,
    String? fileUrl,
    String? approvalStatus,
    String? agentImageUrl,
    String? dateOfBirth,
    List<String>? area,
  }) {
    return ServiceAgentDocument(
      id: id ?? this.id,
      agentName: agentName ?? this.agentName,
      serviceType: serviceType ?? this.serviceType,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      documentName: documentName ?? this.documentName,
      documentType: documentType ?? this.documentType,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      status: status ?? this.status,
      description: description ?? this.description,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      fileUrl: fileUrl ?? this.fileUrl,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      agentImageUrl: agentImageUrl ?? this.agentImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      area: area ?? this.area,
    );
  }

  static List<ServiceAgentDocument> getMockData() {
    return [];
  }
}
