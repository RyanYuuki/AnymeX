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
