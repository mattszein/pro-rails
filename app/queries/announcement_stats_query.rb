class AnnouncementStatsQuery
  def self.call
    {
      total: Announcement.count,
      draft: Announcement.draft.count,
      scheduled: Announcement.scheduled.count,
      published: Announcement.published.count
    }
  end
end
