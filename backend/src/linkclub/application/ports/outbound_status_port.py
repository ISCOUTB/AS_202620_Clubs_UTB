from abc import ABC, abstractmethod


class StatusPort(ABC):
    @abstractmethod
    def get_status(self) -> str:
        ...