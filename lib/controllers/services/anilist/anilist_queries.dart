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
          userPreferred
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
        favourites
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
        studios(isMain: true) {
          nodes {
            id
            name
            siteUrl
          }
        }
        characters(sort: [ROLE, FAVOURITES_DESC], perPage: 25, page: 1) {
          edges {
            role
            node {
              id
              name {
                full
                userPreferred
              }
              favourites
              image {
                large
              }
              description
              isFavourite
            }
            voiceActors(language: JAPANESE) {
              id
              name {
                full
                userPreferred
              }
              image {
                large
              }
              languageV2
            }
          }
        }
        staffPreview: staff(perPage: 25, sort: [RELEVANCE, ID]) {
          edges {
            role
            node {
              id
              name {
                full
                userPreferred
              }
              image {
                large
              }
            }
          }
        }
        relations {
          edges {
            relationType(version: 2)
            node {
              id
              idMal
              title {
                romaji
                english
                userPreferred
              }
              coverImage {
                large
              }
              type
              status(version: 2)
              averageScore
            }
          }
        }
        recommendations(sort: RATING_DESC) {
          nodes {
            mediaRecommendation {
              id
              title {
                romaji
                english
                userPreferred
              }
              coverImage {
                large
              }
              type
              averageScore
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
        externalLinks {
          url
          site
        }
      }
      Page(page: 1) {
        mediaList(isFollowing: true, sort: [STATUS], mediaId: \$id) {
          id
          status
          score(format: POINT_100)
          progress
          user {
            id
            name
            avatar {
              large
            }
          }
        }
      }
    }
  ''';
