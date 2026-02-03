return {
	Name = "set-countdown";
	Description = "Sets game countdown value to provided.";
	Group = "Interface";
	Args = {
		{
			Type = "integer";
			Name = "value";
			Description = "Countdown value to set (in seconds)."
		}
	}
}
