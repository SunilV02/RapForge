namespace rap.battle;

using { cuid, managed, Currency } from '@sap/cds/common';

// An artist who participates in battles
entity Artists : cuid, managed {
    name        : String(100) not null;
    stageName   : String(100);
    city        : String(100);
    bio         : String(500);
    battles     : Association to many BattleParticipants on battles.artist = $self;
}

// A rap battle event
entity Battles : cuid, managed {
    title       : String(200) not null;
    date        : Date;
    venue       : String(200);
    status      : String enum { upcoming; ongoing; completed; } default 'upcoming';
    participants: Composition of many BattleParticipants on participants.battle = $self;
    votes       : Composition of many Votes on votes.battle = $self;
}

// Which artists participate in which battle (many-to-many link)
entity BattleParticipants : cuid {
    battle      : Association to Battles not null;
    artist      : Association to Artists not null;
    score       : Integer default 0;
}

// A vote cast by a user for an artist in a battle
entity Votes : cuid, managed {
    battle      : Association to Battles not null;
    artist      : Association to Artists not null;
    voter       : String(100);   // will be replaced by auth user later
    comment     : String(500);
}
