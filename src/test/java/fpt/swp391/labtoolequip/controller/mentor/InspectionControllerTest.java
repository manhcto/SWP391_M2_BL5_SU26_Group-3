package fpt.swp391.labtoolequip.controller.mentor;

import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class InspectionControllerTest {
	@Test
	void mentorCanCreateAndEditInspections() {
		assertTrue(new TestableInspectionController().canMutateForTest());
	}

	private static final class TestableInspectionController extends InspectionController {
		private boolean canMutateForTest() {
			return canMutate();
		}
	}
}
