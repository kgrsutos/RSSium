import Testing
@testable import RSSium

struct BasicSystemTest {
    
    @Test("Most basic test") 
    func mostBasicTest() {
        #expect(Bool(true))
    }
    
    @Test("Basic arithmetic")
    func basicArithmetic() {
        let result = 2 + 2
        #expect(result == 4)
    }
}