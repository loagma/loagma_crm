import 'package:flutter_test/flutter_test.dart';
import 'package:loagma_crm/models/leave_model.dart';
import 'package:loagma_crm/services/leave_service.dart';

void main() {
  group('Leave Management Tests', () {
    test('LeaveModel should parse JSON correctly', () {
      final json = {
        'id': 'test-id',
        'employeeId': 'emp-123',
        'employeeName': 'John Doe',
        'leaveType': 'Sick',
        'startDate': '2024-12-30T00:00:00.000Z',
        'endDate': '2024-12-31T00:00:00.000Z',
        'numberOfDays': 2,
        'reason': 'Test reason',
        'status': 'PENDING',
        'requestedAt': '2024-12-26T10:00:00.000Z',
      };

      final leave = LeaveModel.fromJson(json);

      expect(leave.id, 'test-id');
      expect(leave.employeeId, 'emp-123');
      expect(leave.employeeName, 'John Doe');
      expect(leave.leaveType, 'Sick');
      expect(leave.numberOfDays, 2);
      expect(leave.reason, 'Test reason');
      expect(leave.status, 'PENDING');
      expect(leave.isPending, true);
      expect(leave.isApproved, false);
      expect(leave.canCancel, true);
    });

    test('LeaveBalance should calculate available leaves correctly', () {
      final json = {
        'id': 'balance-id',
        'employeeId': 'emp-123',
        'year': 2024,
        'sickLeaves': 12,
        'casualLeaves': 10,
        'earnedLeaves': 20,
        'usedSickLeaves': 2,
        'usedCasualLeaves': 1,
        'usedEarnedLeaves': 3,
      };

      final balance = LeaveBalance.fromJson(json);

      expect(balance.availableSickLeaves, 10);
      expect(balance.availableCasualLeaves, 9);
      expect(balance.availableEarnedLeaves, 17);
      expect(balance.totalAvailableLeaves, 36);
      expect(balance.totalUsedLeaves, 6);
      expect(balance.totalAllocatedLeaves, 42);
    });

    test('LeaveService should provide correct leave types', () {
      final leaveTypes = LeaveService.getLeaveTypes();

      expect(leaveTypes, contains('Sick'));
      expect(leaveTypes, contains('Casual'));
      expect(leaveTypes, contains('Earned'));
      expect(leaveTypes, contains('Emergency'));
      expect(leaveTypes, contains('Unpaid'));
    });

    test('LeaveService should provide correct status options', () {
      final statusOptions = LeaveService.getStatusOptions();

      expect(statusOptions, contains('ALL'));
      expect(statusOptions, contains('PENDING'));
      expect(statusOptions, contains('APPROVED'));
      expect(statusOptions, contains('REJECTED'));
      expect(statusOptions, contains('CANCELLED'));
    });

    test('LeaveModel helper methods should work correctly', () {
      final leave = LeaveModel(
        id: 'test-id',
        employeeId: 'emp-123',
        employeeName: 'John Doe',
        leaveType: 'Sick',
        startDate: DateTime(2024, 12, 30),
        endDate: DateTime(2024, 12, 31),
        numberOfDays: 2,
        reason: 'Test reason',
        status: 'PENDING',
        requestedAt: DateTime(2024, 12, 26),
      );

      expect(leave.formattedDateRange, '30/12/2024 - 31/12/2024');
      expect(leave.formattedRequestedAt, '26/12/2024');
      expect(leave.daysText, '2 days');
      expect(leave.isPending, true);
      expect(leave.canCancel, true);
    });

    test('LeaveModel with single day should show correct text', () {
      final leave = LeaveModel(
        id: 'test-id',
        employeeId: 'emp-123',
        employeeName: 'John Doe',
        leaveType: 'Sick',
        startDate: DateTime(2024, 12, 30),
        endDate: DateTime(2024, 12, 30),
        numberOfDays: 1,
        status: 'APPROVED',
        requestedAt: DateTime(2024, 12, 26),
      );

      expect(leave.daysText, '1 day');
      expect(leave.isApproved, true);
      expect(leave.canCancel, false);
    });

    test('LeaveModel status checks should work correctly', () {
      final pendingLeave = LeaveModel(
        id: 'test-1',
        employeeId: 'emp-123',
        employeeName: 'John Doe',
        leaveType: 'Sick',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        numberOfDays: 1,
        status: 'PENDING',
        requestedAt: DateTime.now(),
      );

      final approvedLeave = LeaveModel(
        id: 'test-2',
        employeeId: 'emp-123',
        employeeName: 'John Doe',
        leaveType: 'Casual',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        numberOfDays: 1,
        status: 'APPROVED',
        requestedAt: DateTime.now(),
      );

      final rejectedLeave = LeaveModel(
        id: 'test-3',
        employeeId: 'emp-123',
        employeeName: 'John Doe',
        leaveType: 'Earned',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        numberOfDays: 1,
        status: 'REJECTED',
        requestedAt: DateTime.now(),
      );

      final cancelledLeave = LeaveModel(
        id: 'test-4',
        employeeId: 'emp-123',
        employeeName: 'John Doe',
        leaveType: 'Sick',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        numberOfDays: 1,
        status: 'CANCELLED',
        requestedAt: DateTime.now(),
      );

      expect(pendingLeave.isPending, true);
      expect(pendingLeave.canCancel, true);

      expect(approvedLeave.isApproved, true);
      expect(approvedLeave.canCancel, false);

      expect(rejectedLeave.isRejected, true);
      expect(rejectedLeave.canCancel, false);

      expect(cancelledLeave.isCancelled, true);
      expect(cancelledLeave.canCancel, false);
    });
  });
}
