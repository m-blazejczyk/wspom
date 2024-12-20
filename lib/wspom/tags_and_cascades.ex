defmodule Wspom.TnC do
  alias Wspom.Database
  # This function is called when tags have been edited on the Edit Entry form.
  # Scenarios:
  # - Only TAGS are included. They will be added to the entry and, at a later time,
  #   to the list of tags. Tags cannot contain mistakes; a mistyped tag becomes
  #   a new tag. But we will want to generate a summary of tags that were added.
  # - If CASCADE names are included, there is no problem, either; they will be
  #   converted to the tags that make up the cascade.
  # - But if the text includes at least one CASCADE DEFINITION, we must validate it:
  #   none of the tags names in the cascade may be a name of another cascade.
  #   We will also include new cascades in the summary.
  #
  # In general, tags edited in text form may consist of a combination of any of
  # the following, separated by spaces:
  # - #string# -> A tag cascade name or a single tag
  # - #string#>#string#>#string# -> The definition of a new tag cascade;
  #   the last tag in the cascade will become its name
  #
  # This function returns a lot of information:
  # - Errors (if any)
  # - If there are no errors, a map with the following keys:
  #   - :tags - the MapSet containing the tags to apply to the entry
  #   - :summary - the summary to be displayed to the user on success
  #   - A representation of changes to be made to the list of tags and cascades
  #     stored in the database; we can't make these changes right now in case the
  #     form validation fails in the end; but this way, we'll have the list of all
  #     changes to apply later
  @spec tags_from_string(String.t()) :: {:error, String.t()} | {:ok, %{}}
  def tags_from_string(input) do
    # Grab existing tags & cascades from the database
    {tags_db, cascades_db} = Database.all_tags_and_cascades()

    input
    |> String.split(" ", trim: true)
    # Now, check for cascade names
    # This function also initializes the proper accumulator
    |> apply_cascades(cascades_db)
    # Now, check for cascade definitions
  end

  # This function creates a MapSet of tags from the given list of strings
  # and initializes the accumulator properly
  # It also applies known cascades - if the tag name is the name of a cascade,
  # the tags forming the cascade will be added to the set of tags
  @spec apply_cascades([String.t()]) :: {:error, String.t()} | {:ok, %{}}
  defp apply_cascades(tags, existing_cascades) do
    tags
    |> Enum.reduce(%{tags: MapSet.new()}, fn tag, acc ->
      cascade = existing_cascades |> Map.get(tag)
      if cascade != nil do
        {:ok, cascade |> Enum.reduce(acc, &add_tag/2)}
      else
        {:ok, add_tag(tag, acc)}
      end
    end)
  end

  defp add_tag(tag, %{tags: tags} = acc) do
    Map.update!(acc, :tags, &(MapSet.put(&1, tag)))
  end

end
