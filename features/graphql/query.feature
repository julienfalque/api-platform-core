Feature: GraphQL query support

  @createSchema
  Scenario: Execute an empty GraphQL query
    When I send a "GET" request to "/graphql"
    Then the response status code should be 400
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "errors[0].message" should be equal to "GraphQL query is not valid"

  Scenario: Introspect the GraphQL schema
    When I send the following GraphQL request:
    """
    {
      __schema {
        types {
          name
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.__schema.types" should exist

  Scenario: Introspect types
    When I send the following GraphQL request:
    """
    {
      type1: __type(name: "DummyProduct") {
        description,
        fields {
          name
          type {
            name
            kind
            ofType {
              name
              kind
            }
          }
        }
      }
      type2: __type(name: "DummyAggregateOfferConnection") {
        description,
        fields {
          name
          type {
            name
            kind
            ofType {
              name
              kind
            }
          }
        }
      }
      type3: __type(name: "DummyAggregateOfferEdge") {
        description,
        fields {
          name
          type {
            name
            kind
            ofType {
              name
              kind
            }
          }
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.type1.description" should be equal to "Dummy Product."
    And the JSON node "data.type1.fields[0].type.name" should be equal to "DummyAggregateOfferConnection"
    And the JSON node "data.type2.fields[0].name" should be equal to "edges"
    And the JSON node "data.type2.fields[0].type.ofType.name" should be equal to "DummyAggregateOfferEdge"
    And the JSON node "data.type3.fields[0].name" should be equal to "node"
    And the JSON node "data.type3.fields[1].name" should be equal to "cursor"
    And the JSON node "data.type3.fields[0].type.name" should be equal to "DummyAggregateOffer"

  @dropSchema
  Scenario: Retrieve an item through a GraphQL query
    Given there is 4 dummy objects with relatedDummy
    When I send the following GraphQL request:
    """
    {
      dummyItem: dummy(id: 3) {
        name
        relatedDummy {
          name
          __typename
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummyItem.name" should be equal to "Dummy #3"
    And the JSON node "data.dummyItem.relatedDummy.name" should be equal to "RelatedDummy #3"
    And the JSON node "data.dummyItem.relatedDummy.__typename" should be equal to "RelatedDummy"

  @createSchema
  @dropSchema
  Scenario: Retrieve an item through a GraphQL query with variables
    Given there is 2 dummy objects with relatedDummy
    When I have the following GraphQL request:
    """
    query DummyWithId($itemId: Int = 1) {
      dummyItem: dummy(id: $itemId) {
        name
        relatedDummy {
          name
        }
      }
    }
    """
    When I send the GraphQL request with variables:
    """
    {
      "itemId": 2
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummyItem.name" should be equal to "Dummy #2"
    And the JSON node "data.dummyItem.relatedDummy.name" should be equal to "RelatedDummy #2"

  @createSchema
  @dropSchema
  Scenario: Run a specific operation through a GraphQL query
    Given there is 2 dummy objects
    When I have the following GraphQL request:
    """
    query DummyWithId1 {
      dummyItem: dummy(id: 1) {
        name
      }
    }
    query DummyWithId2 {
      dummyItem: dummy(id: 2) {
        name
      }
    }
    """
    When I send the GraphQL request with operation "DummyWithId2"
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummyItem.name" should be equal to "Dummy #2"
    When I send the GraphQL request with operation "DummyWithId1"
    Then the JSON node "data.dummyItem.name" should be equal to "Dummy #1"

  @createSchema
  @dropSchema
  Scenario: Retrieve an nonexistent item through a GraphQL query
    Given there is 1 dummy objects
    When I send the following GraphQL request:
    """
    {
      dummy(id: 2) {
        name
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummy" should be null

  @createSchema
  @dropSchema
  Scenario: Retrieve a collection through a GraphQL query
    Given there is 4 dummy objects with relatedDummy and its thirdLevel
    When I send the following GraphQL request:
    """
    {
      dummies {
        ...dummyFields
      }
    }
    fragment dummyFields on DummyConnection {
      edges {
        node {
          name
          relatedDummy {
            name
            thirdLevel {
              level
            }
          }
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges[2].node.name" should be equal to "Dummy #3"
    And the JSON node "data.dummies.edges[2].node.relatedDummy.name" should be equal to "RelatedDummy #3"
    And the JSON node "data.dummies.edges[2].node.relatedDummy.thirdLevel.level" should be equal to "3"

  @createSchema
  @dropSchema
  Scenario: Retrieve an nonexistent collection through a GraphQL query
    When I send the following GraphQL request:
    """
    {
      dummies {
        edges {
          node {
            name
          }
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges" should have 0 element
    And the JSON node "data.dummies.pageInfo.endCursor" should be null
    And the JSON node "data.dummies.pageInfo.hasNextPage" should be false

  @createSchema
  @dropSchema
  Scenario: Retrieve a collection with a nested collection through a GraphQL query
    Given there is 4 dummy objects having each 3 relatedDummies
    When I send the following GraphQL request:
    """
    {
      dummies {
        edges {
          node {
            name
            relatedDummies {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges[2].node.name" should be equal to "Dummy #3"
    And the JSON node "data.dummies.edges[2].node.relatedDummies.edges[1].node.name" should be equal to "RelatedDummy23"

  @createSchema
  @dropSchema
  Scenario: Retrieve a collection and an item through a GraphQL query
    Given there is 3 dummy objects with dummyDate
    And there is 2 dummy group objects
    When I send the following GraphQL request:
    """
    {
      dummies {
        edges {
          node {
            name
            dummyDate
          }
        }
      }
      dummyGroup(id: 2) {
        foo
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges[1].node.name" should be equal to "Dummy #2"
    And the JSON node "data.dummies.edges[1].node.dummyDate" should be equal to "2015-04-02T00:00:00+00:00"
    And the JSON node "data.dummyGroup.foo" should be equal to "Foo #2"

  @createSchema
  @dropSchema
  Scenario: Retrieve a specific number of items in a collection through a GraphQL query
    Given there is 4 dummy objects
    When I send the following GraphQL request:
    """
    {
      dummies(first: 2) {
        edges {
          node {
            name
          }
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges" should have 2 elements

  @createSchema
  @dropSchema
  Scenario: Retrieve a specific number of items in a nested collection through a GraphQL query
    Given there is 2 dummy objects having each 5 relatedDummies
    When I send the following GraphQL request:
    """
    {
      dummies(first: 1) {
        edges {
          node {
            name
            relatedDummies(first: 2) {
              edges {
                node {
                  name
                }
              }
            }
          }
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges" should have 1 element
    And the JSON node "data.dummies.edges[0].node.relatedDummies.edges" should have 2 elements

  @createSchema
  @dropSchema
  Scenario: Paginate through collections through a GraphQL query
    Given there is 4 dummy objects having each 4 relatedDummies
    When I send the following GraphQL request:
    """
    {
      dummies(first: 2) {
        edges {
          node {
            name
            relatedDummies(first: 2) {
              edges {
                node {
                  name
                }
                cursor
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
          cursor
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.pageInfo.endCursor" should be equal to "Mw=="
    And the JSON node "data.dummies.pageInfo.hasNextPage" should be true
    And the JSON node "data.dummies.edges[1].node.name" should be equal to "Dummy #2"
    And the JSON node "data.dummies.edges[1].cursor" should be equal to "MQ=="
    And the JSON node "data.dummies.edges[1].node.relatedDummies.pageInfo.endCursor" should be equal to "Mw=="
    And the JSON node "data.dummies.edges[1].node.relatedDummies.pageInfo.hasNextPage" should be true
    And the JSON node "data.dummies.edges[1].node.relatedDummies.edges[0].node.name" should be equal to "RelatedDummy12"
    And the JSON node "data.dummies.edges[1].node.relatedDummies.edges[0].cursor" should be equal to "MA=="
    When I send the following GraphQL request:
    """
    {
      dummies(first: 2, after: "MQ==") {
        edges {
          node {
            name
            relatedDummies(first: 2, after: "MA==") {
              edges {
                node {
                  name
                }
                cursor
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
          cursor
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges[0].node.name" should be equal to "Dummy #3"
    And the JSON node "data.dummies.edges[0].cursor" should be equal to "Mg=="
    And the JSON node "data.dummies.edges[1].node.relatedDummies.edges[0].node.name" should be equal to "RelatedDummy24"
    And the JSON node "data.dummies.edges[1].node.relatedDummies.edges[0].cursor" should be equal to "MQ=="
    When I send the following GraphQL request:
    """
    {
      dummies(first: 2, after: "Mg==") {
        edges {
          node {
            name
            relatedDummies(first: 3, after: "MQ==") {
              edges {
                node {
                  name
                }
                cursor
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
          cursor
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges" should have 1 element
    And the JSON node "data.dummies.pageInfo.hasNextPage" should be false
    And the JSON node "data.dummies.edges[0].node.name" should be equal to "Dummy #4"
    And the JSON node "data.dummies.edges[0].cursor" should be equal to "Mw=="
    And the JSON node "data.dummies.edges[0].node.relatedDummies.pageInfo.hasNextPage" should be false
    And the JSON node "data.dummies.edges[0].node.relatedDummies.edges" should have 2 elements
    And the JSON node "data.dummies.edges[0].node.relatedDummies.edges[1].node.name" should be equal to "RelatedDummy44"
    And the JSON node "data.dummies.edges[0].node.relatedDummies.edges[1].cursor" should be equal to "Mw=="
    When I send the following GraphQL request:
    """
    {
      dummies(first: 2, after: "Mw==") {
        edges {
          node {
            name
            relatedDummies(first: 1, after: "MQ==") {
              edges {
                node {
                  name
                }
                cursor
              }
              pageInfo {
                endCursor
                hasNextPage
              }
            }
          }
          cursor
        }
        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.dummies.edges" should have 0 element

  @createSchema
  @dropSchema
  Scenario: Retrieve an item with composite primitive identifiers through a GraphQL query
    Given there are composite primitive identifiers objects
    When I send the following GraphQL request:
    """
    {
      compositePrimitiveItem(name: "Bar", year: 2017) {
        description
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.compositePrimitiveItem.description" should be equal to "This is bar."

  @createSchema
  @dropSchema
  Scenario: Retrieve an item with composite identifiers through a GraphQL query
    Given there are Composite identifier objects
    When I send the following GraphQL request:
    """
    {
      compositeRelation(compositeItem: {id: 1}, compositeLabel: {id: 1}) {
        value
      }
    }
    """
    Then the response status code should be 200
    And the response should be in JSON
    And the header "Content-Type" should be equal to "application/json"
    And the JSON node "data.compositeRelation.value" should be equal to "somefoobardummy"
