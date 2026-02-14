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

const characterDetailsQuery = '''
  query(\$id: Int) {
    Character(id: \$id) {
      id
      name {
        full
        native
        userPreferred
      }
      image {
        large
      }
      description
      gender
      age
      bloodType
      dateOfBirth {
        year
        month
        day
      }
      favourites
      isFavourite
      media(sort: POPULARITY_DESC, perPage: 25) {
        edges {
          node {
            id
            title {
              userPreferred
              english
              romaji
              native
            }
            coverImage {
              large
            }
            type
            format
            averageScore
            seasonYear
            startDate {
              year
            }
            mediaListEntry {
              status
            }
          }
          characterRole
          voiceActors(sort: [RELEVANCE, ID]) {
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
    }
  }
''';

const staffDetailsQuery = '''
  query(\$id: Int, \$characterPage: Int = 1, \$staffPage: Int = 1) {
    Staff(id: \$id) {
      id
      name {
        full
        native
        userPreferred
      }
      image {
        large
      }
      description
      gender
      age
      dateOfBirth {
        year
        month
        day
      }
      yearsActive
      homeTown
      favourites
      isFavourite
      bloodType
      characters(sort: FAVOURITES_DESC, perPage: 50, page: \$characterPage) {
        pageInfo {
          hasNextPage
          lastPage
        }
        edges {
          node {
            id
            name {
              full
              userPreferred
            }
            image {
              large
            }
            media(sort: POPULARITY_DESC, perPage: 1) {
               nodes {
                 id
                 title {
                   userPreferred
                   english
                   romaji
                   native
                 }
               }
            }
          }
          role
        }
      }
      staffMedia(sort: POPULARITY_DESC, perPage: 50, page: \$staffPage) {
        pageInfo {
          hasNextPage
          lastPage
        }
        edges {
          node {
            id
            title {
              userPreferred
              english
              romaji
              native
            }
            coverImage {
              large
            }
            type
            format
            averageScore
            seasonYear
            startDate {
              year
            }
            mediaListEntry {
              status
            }
          }
          staffRole
        }
      }
    }
  }
''';
