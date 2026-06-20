Feature: smoke test for the karate image

  Scenario: offline assertions execute end-to-end
    * def sum = 1 + 1
    * assert sum == 2
    * def payload = { name: 'karate', ready: true }
    * match payload.name == 'karate'
    * match payload contains { ready: true }
