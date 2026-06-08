import abilityTest from './Ability.test';
import healthGoalServiceTest from './HealthGoalService.test';
import healthDataRecordTest from './HealthDataRecord.test';

export default function testsuite() {
  abilityTest();
  healthGoalServiceTest();
  healthDataRecordTest();
}
