import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { BudgetCalculator } from './budget-calculator';

@Module({
  controllers: [PaymentsController],
  providers: [PaymentsService, BudgetCalculator],
  exports: [PaymentsService, BudgetCalculator],
})
export class PaymentsModule {}
