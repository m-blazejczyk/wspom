defmodule Wspom.BookHistory do
  # This data type is extremely simple but flexible in order to
  # accomodate any type of information that would need to be tracked.
  #
  # We need the id because these records will be editable in a form.
  #
  # :date is a Date object.
  #
  # :type can be one of:
  # - :read - :value should contain the current position in the book
  # - :updated - same as above but this one is used to bulk-advance the
  #   current reading position in situations when detailed reading history
  #   is not available; in other words, the pages were read but not
  #   necessarily on the date indicated
  # - :skipped - same as above but to advance the current reading position
  #   to indicate pages that were not read, i.e. that were skipped
  # - :status - :value should contain a new status (see book.ex);
  #   it is expected that some status changes will be accompanied by
  #   a :read record.
  defstruct [:id, :date, :type, :value]

end
