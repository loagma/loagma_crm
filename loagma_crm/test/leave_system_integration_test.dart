import 'package:flutter_test/flutter_test.dart';
import 'package:loagma_crm/models/leave_model.dart';
import 'package:loagma_crm/services/leave_service.dart';

void main() {
  group('Leave System Integration Tests', () {
    test('Leave model should parse JSON correctly', () {
      final json = {
        'id': '1',
        'employeeId': 'emp123',
        'employeeName': 'John Doe',
        'leaveType': 'Sick',
        'startDate': '2024-01-15T00:00:00.000Z',
        'endDate': '2024-01-16T00:00:00.000Z',
        'numberOfDays': 2,
        'reason': 'Fever and cold',
        'status': 'PENDING',
        'requestedAt': '2024-01-10T10:00:00.000Z',
      };

      final leave = LeaveModel.fromJson(json);

      expect(leave.id, '1');
      expect(leave.employeeId, 'emp123');
      expect(leave.employeeName, 'John Doe');
      expect(leave.leaveType, 'Sick');
      expect(leave.numberOfDays, 2);
      expect(leave.reason, 'Fever and cold');
      expect(leave.status, 'PENDING');
      expect(leave.isPending, true);
      expect(leave.isApproved, false);
      expect(leave.isRejected, false);
      expect(leave.canCancel, true);
    });

    test('Leave balance should calculate correctly', () {
      final json = {
        'id': '1',
        'employeeId': 'emp123',
        'year': 2024,
        'sickLeaves': 12,
        'casualLeaves': 12,
        'earnedLeaves': 21,
        'usedSickLeaves': 2,
        'usedCasualLeaves': 3,
        'usedEarnedLeaves': 5,
      };

      final balance = LeaveBalance.fromJson(json);

      expect(balance.availableSickLeaves, 10);
      expect(balance.availableCasualLeaves, 9);
      expect(balance.availableEarnedLeaves, 16);
      expect(balance.totalAvailableLeaves, 35);
      expect(balance.totalUsedLeaves, 10);
      expect(balance.totalAllocatedLeaves, 45);
    });

    test('Leave service should provide correct leave types', () {
      final leaveTypes = LeaveService.getLeaveTypes();

      expect(leaveTypes, contains('Sick'));
      expect(leaveTypes, contains('Casual'));
      expect(leaveTypes, contains('Earned'));
      expect(leaveTypes, contains('Emergency'));
      expect(leaveTypes, contains('Unpaid'));
    });

    test('Leave service should provide correct status options', () {
      final statusOptions = LeaveService.getStatusOptions();

      expect(statusOptions, contains('ALL'));
      expect(statusOptions, contains('PENDING'));
      expect(statusOptions, contains('APPROVED'));
      expect(statusOptions, contains('REJECTED'));
      expect(statusOptions, contains('CANCELLED'));
    });

    test('Leave model should format dates correctly', () {
      final leave = LeaveModel(
        id: '1',
        employeeId: 'emp123',
        employeeName: 'John Doe',
        leaveType: 'Sick',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 16),
        numberOfDays: 2,
        reason: 'Test reason',
        status: 'PENDING',
        requestedAt: DateTime(2024, 1, 10),
        createdAt: DateTime(2024, 1, 10),
        updatedAt: DateTime(2024, 1, 10),
      );

      expect(leave.formattedDateRange, '15/1/2024 - 16/1/2024');
      expect(leave.formattedRequestedAt, '10/1/2024');
      expect(leave.daysText, '2 days');
    });

    test('Single day leave should format correctly', () {
      final leave = LeaveModel(
        id: '1',
        employeeId: 'emp123',
        employeeName: 'John Doe',
        leaveType: 'Sick',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
        numberOfDays: 1,
        reason: 'Test reason',
        status: 'PENDING',
        requestedAt: DateTime(2024, 1, 10),
        createdAt: DateTime(2024, 1, 10),
        updatedAt: DateTime(2024, 1, 10),
      );

      expect(leave.daysText, '1 day');
    });
  });
}
