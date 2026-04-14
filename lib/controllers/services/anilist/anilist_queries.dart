const detailsPrimaryQuery = '''
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
        synonyms
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
            id
            name
          }
        }
        characters(sort: [ROLE, FAVOURITES_DESC], perPage: 25, page: 1) {
          edges {
            node {
              id
              name {
                full
              }
              favourites
              image {
                large
              }
            }
            voiceActors(language: JAPANESE) {
              id
              languageV2
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
        isFavourite
        favourites
        rankings {
          rank
          type
          year
        }
      }
    }
  ''';

const detailsSecondaryQuery = '''
    query (\$id: Int) {
      Media(id: \$id) {
        id
        isFavourite
        favourites
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


const String reviewsQuery = r'''
query ($mediaId: Int, $page: Int, $perPage: Int, $sort: [ReviewSort]) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    reviews(mediaId: $mediaId, sort: $sort) {
      id
      userId
      mediaId
      mediaType
      summary
      body(asHtml: true)
      score
      rating
      ratingAmount
      userRating
      private
      siteUrl
      createdAt
      updatedAt
      user {
        id
        name
        avatar {
          large
        }
      }
      media {
        id
        title {
          userPreferred
        }
        coverImage {
          large
        }
        bannerImage
        type
      }
    }
  }
}
''';

const String reviewDetailQuery = r'''
query ($id: Int) {
  Review(id: $id) {
    id
    userId
    mediaId
    mediaType
    summary
    body(asHtml: true)
    score
    rating
    ratingAmount
    userRating
    private
    siteUrl
    createdAt
    updatedAt
    user {
      id
      name
      avatar {
        large
      }
    }
    media {
      id
      title {
        userPreferred
      }
      coverImage {
        large
      }
      bannerImage
      type
    }
  }
}
''';

const String saveReviewMutation = r'''
mutation SaveReview($id: Int, $mediaId: Int, $body: String, $summary: String, $score: Int, $private: Boolean) {
  SaveReview(id: $id, mediaId: $mediaId, body: $body, summary: $summary, score: $score, private: $private) {
    id
    userId
    mediaId
    summary
    body(asHtml: true)
    score
    rating
    userRating
    private
    createdAt
    updatedAt
  }
}
''';

const String deleteReviewMutation = r'''
mutation DeleteReview($id: Int) {
  DeleteReview(id: $id) {
    deleted
  }
}
''';

const String rateReviewMutation = r'''
mutation RateReview($reviewId: Int, $rating: ReviewRating) {
  RateReview(reviewId: $reviewId, rating: $rating) {
    id
    userRating
    rating
    ratingAmount
  }
}
''';


const String threadsQuery = r'''
query ($page: Int, $perPage: Int, $categoryId: Int, $mediaCategoryId: Int, $search: String, $sort: [ThreadSort], $userId: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    threads(categoryId: $categoryId, mediaCategoryId: $mediaCategoryId, search: $search, sort: $sort, userId: $userId) {
      id
      title
      body
      userId
      replyUserId
      replyCommentId
      replyCount
      viewCount
      isLocked
      isSticky
      isSubscribed
      likeCount
      isLiked
      repliedAt
      createdAt
      updatedAt
      user {
        id
        name
        avatar {
          large
        }
      }
      replyUser {
        id
        name
        avatar {
          large
        }
      }
      siteUrl
      categories {
        id
        name
      }
      mediaCategories {
        id
        title {
          userPreferred
        }
      }
    }
  }
}
''';

const String threadDetailQuery = r'''
query ($id: Int) {
  Thread(id: $id) {
    id
    title
    body(asHtml: true)
    userId
    replyUserId
    replyCommentId
    replyCount
    viewCount
    isLocked
    isSticky
    isSubscribed
    likeCount
    isLiked
    repliedAt
    createdAt
    updatedAt
    user {
      id
      name
      avatar {
        large
      }
    }
    replyUser {
      id
      name
      avatar {
        large
      }
    }
    siteUrl
    categories {
      id
      name
    }
    mediaCategories {
      id
      title {
        userPreferred
      }
    }
  }
}
''';

const String saveThreadMutation = r'''
mutation SaveThread($id: Int, $title: String, $body: String, $categories: [Int], $mediaCategories: [Int]) {
  SaveThread(id: $id, title: $title, body: $body, categories: $categories, mediaCategories: $mediaCategories) {
    id
    title
    body
    createdAt
    updatedAt
  }
}
''';

const String deleteThreadMutation = r'''
mutation DeleteThread($id: Int) {
  DeleteThread(id: $id) {
    deleted
  }
}
''';

const String toggleThreadSubscriptionMutation = r'''
mutation ToggleThreadSubscription($threadId: Int, $subscribe: Boolean) {
  ToggleThreadSubscription(threadId: $threadId, subscribe: $subscribe) {
    id
    isSubscribed
  }
}
''';


const String threadCommentsQuery = r'''
query ($threadId: Int, $page: Int, $perPage: Int, $sort: [ThreadCommentSort]) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    threadComments(threadId: $threadId, sort: $sort) {
      id
      userId
      threadId
      comment(asHtml: true)
      likeCount
      isLiked
      siteUrl
      createdAt
      updatedAt
      user {
        id
        name
        avatar {
          large
        }
      }
      childComments
      isLocked
    }
  }
}
''';

const String saveThreadCommentMutation = r'''
mutation SaveThreadComment($id: Int, $threadId: Int, $parentCommentId: Int, $comment: String) {
  SaveThreadComment(id: $id, threadId: $threadId, parentCommentId: $parentCommentId, comment: $comment) {
    id
    threadId
    comment(asHtml: true)
    createdAt
    updatedAt
    user {
      id
      name
      avatar {
        large
      }
    }
  }
}
''';

const String deleteThreadCommentMutation = r'''
mutation DeleteThreadComment($id: Int) {
  DeleteThreadComment(id: $id) {
    deleted
  }
}
''';

const String userSearchQuery = r'''
query ($search: String, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    users(search: $search, sort: [SEARCH_MATCH]) {
      id
      name
      avatar {
        large
      }
      bannerImage
      isFollowing
      isFollower
      about(asHtml: true)
      favourites {
        anime { nodes { id title { userPreferred } coverImage { large } } }
        manga { nodes { id title { userPreferred } coverImage { large } } }
        characters { nodes { id name { full } image { large } } }
      }
      statistics {
        anime { count episodesWatched minutesWatched }
        manga { count chaptersRead volumesRead }
      }
    }
  }
}
''';

const String staffSearchQuery = r'''
query ($search: String, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    staff(search: $search, sort: [SEARCH_MATCH, FAVOURITES_DESC]) {
      id
      name {
        full
        native
      }
      image {
        large
      }
      primaryOccupations
      gender
      dateOfBirth {
        year
      }
      favourites
      isFavourite
    }
  }
}
''';

const String characterSearchQuery = r'''
query ($search: String, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    characters(search: $search, sort: [SEARCH_MATCH, FAVOURITES_DESC]) {
      id
      name {
        full
        native
      }
      image {
        large
      }
      gender
      age
      favourites
      isFavourite
      media(sort: POPULARITY_DESC, perPage: 3) {
        nodes {
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

const String mediaSearchQuery = r'''
query ($search: String, $type: MediaType, $page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    pageInfo {
      hasNextPage
      currentPage
    }
    media(search: $search, type: $type, sort: [SEARCH_MATCH, POPULARITY_DESC]) {
      id
      title {
        userPreferred
        english
        romaji
      }
      coverImage {
        large
        color
      }
      type
      format
      averageScore
      popularity
      episodes
      chapters
      status
      seasonYear
      genres
      isFavourite
    }
  }
}
''';

const String toggleFavouriteAnimeMutation = r'''
mutation ($id: Int) {
  ToggleFavourite(animeId: $id) {
    anime { nodes { id } }
  }
}
''';

const String toggleFavouriteMangaMutation = r'''
mutation ($id: Int) {
  ToggleFavourite(mangaId: $id) {
    manga { nodes { id } }
  }
}
''';
