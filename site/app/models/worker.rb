# MLcomp: website for automatic and standarized execution of algorithms on datasets.
# Copyright (C) 2010 by Percy Liang and Jake Abernethy
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Worker < ActiveRecord::Base
  belongs_to :user
  belongs_to :current_run, :class_name => "Run", :foreign_key => "current_run_id"

  validates_presence_of   :handle
  validates_uniqueness_of :handle

  WorkerTimeout = 30 * 60 # 30 minutes

  # This is screwed up
  def self.countActive; self.count(:conditions => ["updated_at >= now() - #{WorkerTimeout}"]) end
  def self.countInactive; self.count(:conditions => ["updated_at < now() - #{WorkerTimeout}"]) end
  def self.findInactive; self.find(:all, :conditions => ["updated_at < now() - #{WorkerTimeout}"]) end
  def active?; self.updated_at >= Time.now - WorkerTimeout end
  #def self.countActiveManual; self.find(:all).count { |w| w.active? } end # count not supported in crappy old Ruby
  def self.countActiveManual; self.find(:all).map { |w| w.active? ? w : nil }.compact.size end

  def self.findByHandle(handle)
    matches = find(:all, :conditions => ['handle = ?', handle])
    if matches.size == 1
      matches[0]
    else
      raise WorkerException.new("Found #{matches.size} workers with handle '#{handle}'; wanted exactly one")
    end
  end

  def killCurrentRun
    self.command = "killCurrent"
    saveOrRaise(true)
  end

  # Save or throw an exception
  def saveOrRaise(validate)
    raise WorkerException.new("Unable to save dataset #{self.id}: #{errors.full_messages.join('; ')}") if not save(validate)
  end
end
