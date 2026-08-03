using { rap.battle as db } from '../db/schema';

// Seed Artists
extend db.Artists with @(
    title: 'Artists'
);
