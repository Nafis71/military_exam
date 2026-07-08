import '../../../../shared/domain/entities/exam_entities.dart';

class McqOptionModel {
  const McqOptionModel({required this.id, required this.label});

  final String id;
  final String label;

  factory McqOptionModel.fromJson(Map<String, dynamic> json) {
    return McqOptionModel(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  McqOption toEntity() => McqOption(id: id, label: label);
}
