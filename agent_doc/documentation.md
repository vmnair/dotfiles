# Documentation related instructions

- Never create documentations unless explicitly asked to other than the
  following
- For each project two markdown files needed to be created 1) README.md 2)
  [APPNAME]\_devdocs.md
- `README.md` should clearly explain the functionality of the application, how
  to use it, what are the dependencies and other useful information. This is
  intended for the software developer.
- [APPNAME]\_devdocs (from now on I will address this file as `devdocs.md`)file
  should be generated before ending a session.
- `devdocs.md` shoul
- The `devdocs` file should show a summary of what has been done sofar as well
  as what the next steps are.
- This is intended for the agent (Next Claude instance), it should clearly
  describe the progress sofar as well as next steps when the claude instance is
  restarted.
- The `devdocs` file should cleaned up each time to only include relevant
  information regarding the projects as well as any errors or bugs that has been
  fixed.
- A check-list of the application progress need to be maintained in the
  `devdocs.md` file.
