-- migrate:up
CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('member', 'librarian')),
  login text NOT NULL UNIQUE,
  password_hash text NOT NULL
);

CREATE TABLE board_games (
  id text PRIMARY KEY,
  title text NOT NULL
);

CREATE TABLE game_copies (
  id text PRIMARY KEY,
  game_id text NOT NULL REFERENCES board_games (id),
  condition text NOT NULL CHECK (condition IN ('usable', 'in_inspection', 'damaged'))
);

CREATE TABLE loans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id text NOT NULL REFERENCES users (id),
  game_id text NOT NULL REFERENCES board_games (id),
  copy_id text REFERENCES game_copies (id),
  duration_days int NOT NULL CHECK (duration_days > 0),
  requested_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'approved', 'picked_up', 'returned', 'rejected', 'cancelled')),
  pickup_deadline timestamptz,
  due_at timestamptz,
  returned_at timestamptz
);

CREATE UNIQUE INDEX loans_one_active_per_copy ON loans (copy_id) WHERE status IN ('approved', 'picked_up');

-- migrate:down
DROP TABLE loans;
DROP TABLE game_copies;
DROP TABLE board_games;
DROP TABLE users;
