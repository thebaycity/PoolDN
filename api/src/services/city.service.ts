import { eq, like, and } from 'drizzle-orm';
import { DrizzleD1Database } from 'drizzle-orm/d1';
import { countries, cities } from '../db/schema';

export async function searchCities(db: DrizzleD1Database, countryCode?: string, query?: string) {
  const code = countryCode || 'VN';
  const conditions = [eq(cities.countryCode, code)];

  if (query) {
    conditions.push(like(cities.name, `%${query}%`));
  }

  const results = await db
    .select({
      id: cities.id,
      name: cities.name,
      countryCode: cities.countryCode,
      countryName: countries.name,
    })
    .from(cities)
    .innerJoin(countries, eq(cities.countryCode, countries.code))
    .where(and(...conditions))
    .orderBy(cities.name)
    .limit(50)
    .all();

  return results;
}

export async function listCountries(db: DrizzleD1Database) {
  return db.select().from(countries).orderBy(countries.name).all();
}
