// Public shape of a user; never exposes passwordHash
export function toPublicUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    email: user.email,
    full_name: user.full_name,
    role: user.role,
    family_id: user.family_id
  };
}
