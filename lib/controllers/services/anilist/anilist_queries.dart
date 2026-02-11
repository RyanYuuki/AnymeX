const detailsQuery = '''
    query (\$id: Int) {
      Media(id: \$id) {
        id
        idMal
        isAdult
        title {
          romaji
          english
          native
        }
        description
        coverImage {
          color
          large   
        }
        bannerImage
        type
        averageScore
        episodes
        type
        season
        seasonYear
        duration
        status
        chapters
        format
        popularity
        startDate {
          year
          month
          day
        }
        endDate {
          year
          month
          day
        }
        genres
        studios {
          nodes {
            name
          }
        }
        characters {
          edges {
            node {
              name {
                full
              }
              favourites
              image {
                large
              }
            }
            voiceActors(language: JAPANESE) {
              name {
                full
              }
              image {
                large
              }
            }
          }
        }
        relations {
          edges {
            relationType
            node {
              id
              title {
                romaji
                english
              }
              coverImage {
                large
              }
              bannerImage
              type
              status
              averageScore

            }
          }
        }
        recommendations {
          edges {
            node {
              mediaRecommendation {
                id
                title {
                  romaji
                  english
                }
                coverImage {
                  large
                }
                type
averageScore
              }
            }
          }
        }
        nextAiringEpisode {
          airingAt
          timeUntilAiring
          episode
        }
        rankings {
          rank
          type
          year
        }
      }
    }
  ''';

const airingScheduleQuery = '''
query (\$page: Int, \$perPage: Int, \$airingAtGreater: Int, \$airingAtLesser: Int) {
  Page(page: \$page, perPage: \$perPage) {
    pageInfo {
      hasNextPage
      total
    }
    airingSchedules(
      airingAt_greater: \$airingAtGreater
      airingAt_lesser: \$airingAtLesser
      sort: TIME_DESC
    ) {
      id
      episode
      airingAt
      media {
        id
        title {
          romaji
          english
          native
        }
        coverImage {
          extraLarge
          large
          medium
          color
        }
        type
        format
        averageScore
        favourites
        isAdult
      }
    }
  }
}
''';

const notificationQuery = '''
query (\$page: Int, \$perPage: Int) {
  Page(page: \$page, perPage: \$perPage) {
    pageInfo {
      hasNextPage
      total
    }
    notifications(type_in: [AIRING, RELATED_MEDIA_ADDITION], resetNotificationCount: false) {
      ... on AiringNotification {
        id
        type
        episode
        contexts
        createdAt
        media {
          id
          title {
            userPreferred
          }
          coverImage {
            large
          }
          type
        }
      }
      ... on RelatedMediaAdditionNotification {
        id
        type
        context
        createdAt
        media {
          id
          title {
            userPreferred
          }
          coverImage {
            large
          }
          type
        }
      }
    }
  }
}
''';
