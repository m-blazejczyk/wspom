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
  #   its name may be the same as the name of another cascade.
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
  #   - :tags_applied - a MapSet containing the tags to apply to the entry
  #   - :cascade_defs - a map containing the definitions of new cascades (may be empty)
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
    # Process the tags, checking for cascade names & definitions.
    # This function also initializes the accumulator for subsequent steps.
    |> phase_one(tags_db, cascades_db)
    # Validate cascade definitions.
    |> validate_cascade_defs()
    # Divide tags into "known" and "unknown"
    |> detect_known_tags()
    # Build a summary
    |> build_summary()
  end

  # This function creates a MapSet of tags from the given list of strings.
  # It also processes the tags, applies known cascades - if the tag name is the
  # name of a cascade, the tags forming the cascade will be added to the set of tags.
  # This function also processes cascade definitions into a separate.
  @spec phase_one([String.t()], MapSet.t(), %{}) ::
    {:error, String.t()} | {:ok, %{}}
  defp phase_one(tags, existing_tags, existing_cascades) do
    initial_acc = %{tags_applied: MapSet.new(), cascade_defs: %{},
      existing_tags: existing_tags, existing_cascades: existing_cascades}
    {
      :ok,
      tags
      |> Enum.reduce(initial_acc, fn tag, acc ->
        if tag |> String.contains?(">") do
          # It's a cascade definition - handle it separately
          process_cascade_def(tag, acc)
        else
          # It's a regular tag - see if it's the name of a cascade
          cascade = existing_cascades |> Map.get(tag)
          if cascade != nil do
            cascade |> Enum.reduce(acc, &add_tag_token/2)
          else
            add_tag_token(tag, acc)
          end
        end
      end)
    }
  end

  defp add_tag_token(tag, %{tags_applied: tags} = acc) do
    %{acc | tags_applied: tags |> MapSet.put(tag)}
  end

  defp process_cascade_def(cascade_def, %{cascade_defs: cascade_defs} = acc) do
    cascade_elems = cascade_def |> String.split(">")

    [cascade_name | _] = Enum.reverse(cascade_elems)
    cascade_set = MapSet.new(cascade_elems)

    # This code has one "special" behavior: it will add tags from every
    # cascade definition to `tags_applied`, even if the definition is either
    # duplicated (two different definitions with the same names) or if a cascade
    # with this name already exists
    new_acc = cascade_elems |> Enum.reduce(acc, &add_tag_token/2)

    %{new_acc | cascade_defs: cascade_defs |> Map.put(cascade_name, cascade_set)}
  end

  defp validate_cascade_defs({:error, _} = err), do: err
  defp validate_cascade_defs({:ok, %{cascade_defs: cascade_defs} = acc}) do
    cascade_defs
    |> Enum.reduce({:ok, acc}, &validate_cascade_def/2)
  end

  # When this function returns :ok, the tuple contains:
  # - The set of all tags that are a part of the cascade definitions
  # - The map of the new cascades
  # The last element of the tuple is considered read-only
  defp validate_cascade_def(_, {:error, _} = err), do: err
  defp validate_cascade_def({cascade_name, _}, {:ok, %{existing_cascades: existing_cascades} = acc}) do
    if existing_cascades |> Map.has_key?(cascade_name) do
      {:error, "Existing cascade name '#{cascade_name}' is used in a cascade definition"}
    else
      {:ok, acc}
    end
  end

  defp detect_known_tags({:error, _} = err), do: err
  defp detect_known_tags({:ok, %{tags_applied: tags, existing_tags: existing_tags} = acc}) do
    {known, unknown} = tags
    |> MapSet.split_with(fn tag -> existing_tags |> MapSet.member?(tag) end)

    {:ok, acc |> Map.put(:known_tags, known) |> Map.put(:unknown_tags, unknown)}
  end

  defp build_summary({:error, _} = err), do: err
  defp build_summary({:ok, %{cascade_defs: cascades, known_tags: known_tags, unknown_tags: unknown_tags} = acc}) do
    {:ok, acc |> Map.put(:summary,
      "Applied #{MapSet.size(known_tags) + MapSet.size(unknown_tags)} tags.\n"
      <> "Known tags: #{known_tags |> Enum.sort() |> Enum.join(", ")}\n"
      <> "New tags: #{unknown_tags |> Enum.sort() |> Enum.join(", ")}\n"
      <> "New cascades: #{cascades |> Map.keys() |> Enum.sort() |> Enum.join(", ")}")}
  end
end
